#!/usr/bin/env node
/**
 * Workbench monitor: one place to watch the local workbench stack end to end.
 *
 * It sits *between* the services rather than inside them, so no sub-repo changes:
 *
 *   taps      One small HTTP reverse proxy per caller->callee edge (backend->mock,
 *             mock->config, onix->mock, ...). scripts/dev.js points each service's
 *             upstream URL at its tap, so every inter-service request is recorded with
 *             its caller, callee, status, latency, headers and bodies. Because each
 *             edge has its own port, the caller is known without guessing.
 *   api tap   The api-service base (http://workbench.localhost) is baked into ONDC
 *             payloads (bap_uri/bpp_uri), so its URL cannot change. Instead the monitor
 *             takes over port 80 and the ONIX container moves to 127.0.0.1:8080; the
 *             container's own hops (/mock -> /buyer|/seller) are sent back out through
 *             the host (extra_hosts: host-gateway), so they are captured too. This is
 *             also where a 404 for a domain/version the build does not serve shows up.
 *   grpc tap  ONIX reports every API event to the recorder over gRPC
 *             (/beckn.audit.v1.AuditService/LogEvent, a BytesValue of raw JSON). The
 *             monitor proxies that HTTP/2 stream and decodes each event, so "what did
 *             the recorder get, for which session/transaction" is visible.
 *   logs      scripts/dev.js forwards every prefixed output line (POST /ingest/logs).
 *
 * Everything is correlated by transaction_id, session_id, message_id and action,
 * pulled from query strings, ONDC contexts and JSON bodies (and from log lines by
 * pattern). State is in memory (ring buffers), so it resets with the process; use
 * the UI's export to keep a run.
 *
 * Zero dependencies on purpose (node:http, node:http2, node:zlib), like the rest of
 * scripts/ -- the workspace root must never grow a node_modules.
 *
 * Config comes from MONITOR_CONFIG (JSON) set by dev.js:
 *   { port, taps: [{ name, from, to, listen, target, host? }], grpcTaps: [...],
 *     apiTap: { listen, target } | null, health: [{ service, host, port }] }
 */
const http = require("http");
const http2 = require("http2");
const https = require("https");
const net = require("net");
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

const config = JSON.parse(process.env.MONITOR_CONFIG || "{}");
const PORT = Number(config.port || 4400);
const MAX_REQUESTS = 5000;
const MAX_LOGS = 20000;
const MAX_BODY = 512 * 1024; // bodies above this are stored truncated

// -- store -------------------------------------------------------------------
const requests = []; // newest last
const logs = [];
const txnToSessions = new Map(); // transaction_id -> Set(session_id)
const sessionToTxns = new Map();
const clients = new Set(); // SSE responses
let seq = 0;

function link(txn, session) {
	if (!txn || !session) return;
	if (!txnToSessions.has(txn)) txnToSessions.set(txn, new Set());
	txnToSessions.get(txn).add(session);
	if (!sessionToTxns.has(session)) sessionToTxns.set(session, new Set());
	sessionToTxns.get(session).add(txn);
}

function push(list, max, item, kind) {
	list.push(item);
	if (list.length > max) list.splice(0, list.length - max);
	const data = `event: ${kind}\ndata: ${JSON.stringify(item)}\n\n`;
	for (const res of clients) res.write(data);
}

// -- id extraction -------------------------------------------------------------
const UUID = "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}";
const SESSION_ID = "[A-Za-z0-9_-]{24,40}";
const PATTERNS = {
	transaction_id: new RegExp(`(?:transaction_?id|transactionId|txn(?:Id)?|\\btx)["'\\s:=]+(${UUID})`, "i"),
	message_id: new RegExp(`(?:message_?id|messageId)["'\\s:=]+(${UUID})`, "i"),
	session_id: new RegExp(`(?:session_?id|sessionId)["'\\s:=]+(${SESSION_ID})`, "i"),
	action: /(?:"action"\s*:\s*"|\baction[=:]\s*)([a-z_]{3,20})/,
};

function idsFromText(text) {
	const ids = {};
	if (!text) return ids;
	const sample = text.length > 40000 ? text.slice(0, 40000) : text;
	for (const [key, re] of Object.entries(PATTERNS)) {
		const m = re.exec(sample);
		if (m) ids[key] = m[1];
	}
	return ids;
}

function parseJson(text) {
	if (!text) return undefined;
	try {
		return JSON.parse(text);
	} catch {
		return undefined;
	}
}

/** Pull correlation ids out of a request: query string, ONDC context, JSON fields. */
function extractIds(urlObj, reqJson, reqText, resJson, resText) {
	const q = urlObj ? Object.fromEntries(urlObj.searchParams) : {};
	const ctx = (reqJson && reqJson.context) || (resJson && resJson.context) || {};
	const pick = (...vals) => vals.find((v) => typeof v === "string" && v.length > 0);
	const fromText = { ...idsFromText(resText), ...idsFromText(reqText) };
	// The api-service routes on the domain/version in its path, not the payload's.
	const routed = urlObj && /\/api-service\/([^/]+)\/([^/]+)\//.exec(decodeURIComponent(urlObj.pathname));
	const ids = {
		transaction_id: pick(
			ctx.transaction_id,
			q.transaction_id,
			reqJson?.transaction_id,
			reqJson?.transactionId,
			resJson?.transactionId,
			fromText.transaction_id
		),
		message_id: pick(ctx.message_id, fromText.message_id),
		session_id: pick(
			q.session_id,
			q.sessionId,
			reqJson?.session_id,
			reqJson?.sessionId,
			resJson?.sessionId,
			fromText.session_id
		),
		action: pick(ctx.action, fromText.action),
		flow_id: pick(q.flow_id, reqJson?.flow_id),
		subscriber_url: pick(q.subscriber_url, reqJson?.subscriberUrl),
		domain: pick(routed?.[1], ctx.domain, q.domain, reqJson?.domain),
		version: pick(routed?.[2], ctx.version, ctx.core_version, q.version, reqJson?.version),
		bap_uri: pick(ctx.bap_uri),
		bpp_uri: pick(ctx.bpp_uri),
	};
	for (const k of Object.keys(ids)) if (ids[k] === undefined) delete ids[k];
	link(ids.transaction_id, ids.session_id);
	return ids;
}

// -- recording ------------------------------------------------------------------
function decodeBody(buf, encoding) {
	if (!buf || !buf.length) return "";
	try {
		if (encoding === "gzip") buf = zlib.gunzipSync(buf);
		else if (encoding === "br") buf = zlib.brotliDecompressSync(buf);
		else if (encoding === "deflate") buf = zlib.inflateSync(buf);
	} catch {
		return `<${buf.length} bytes, undecodable ${encoding}>`;
	}
	const text = buf.toString("utf8");
	return text.length > MAX_BODY ? text.slice(0, MAX_BODY) + "\n…[truncated]" : text;
}

const HIDDEN_HEADERS = new Set(["x-api-key", "authorization", "cookie", "set-cookie"]);
function safeHeaders(h) {
	const out = {};
	for (const [k, v] of Object.entries(h || {})) {
		if (k.startsWith(":")) continue;
		out[k] = HIDDEN_HEADERS.has(k.toLowerCase())
			? k.toLowerCase() === "authorization"
				? String(v).slice(0, 48) + "…"
				: "‹redacted›"
			: v;
	}
	return out;
}

function record(entry) {
	entry.id = ++seq;
	push(requests, MAX_REQUESTS, entry, "request");
}

// -- HTTP taps ------------------------------------------------------------------
/** The api tap names its caller by path and source address (see header). */
function apiEdge(req, pathname) {
	// Docker Desktop delivers host-gateway traffic from 127.0.0.1, so the source address
	// alone cannot tell. ONIX's own proxied hops carry the session cookies it sets.
	const fromContainer =
		/(^|;\s*)(mock_url|subscriber_url)=/.test(req.headers.cookie || "") ||
		!/^(::1|127\.0\.0\.1|::ffff:127\.0\.0\.1)$/.test(req.socket.remoteAddress || "");
	if (/\/mock\//.test(pathname)) return { from: fromContainer ? "onix" : "mock", to: "onix" };
	if (/\/(buyer|seller)\//.test(pathname)) return { from: fromContainer ? "onix" : "participant", to: "onix" };
	return { from: fromContainer ? "onix" : "client", to: "onix" };
}

function startTap(tap) {
	const target = new URL(tap.target);
	const client = target.protocol === "https:" ? https : http;
	const server = http.createServer((req, res) => {
		const started = Date.now();
		const chunks = [];
		req.on("data", (c) => chunks.push(c));
		req.on("end", () => {
			const reqBuf = Buffer.concat(chunks);
			const urlObj = new URL(req.url, "http://tap");
			const edge = tap.api ? apiEdge(req, urlObj.pathname) : { from: tap.from, to: tap.to };
			const headers = { ...req.headers, host: target.host };
			delete headers["accept-encoding"]; // keep captured bodies readable
			const upstream = client.request(
				{
					protocol: target.protocol,
					hostname: target.hostname,
					port: target.port || (target.protocol === "https:" ? 443 : 80),
					method: req.method,
					path: req.url,
					headers,
				},
				(up) => {
					// Stream through (SSE responses must not be buffered), capturing a copy.
					res.writeHead(up.statusCode, up.headers);
					const resChunks = [];
					let captured = 0;
					up.on("data", (c) => {
						res.write(c);
						if (captured < MAX_BODY) resChunks.push(c);
						captured += c.length;
					});
					up.on("end", () => {
						res.end();
						finish(up.statusCode, up.headers, Buffer.concat(resChunks));
					});
					up.on("error", () => res.destroy());
				}
			);
			upstream.on("error", (err) => {
				if (!res.headersSent) {
					res.writeHead(502, { "content-type": "application/json" });
					res.end(JSON.stringify({ error: `monitor: ${tap.name} upstream unreachable`, detail: err.message }));
				}
				finish(502, {}, Buffer.alloc(0), err.message);
			});
			upstream.end(reqBuf);

			function finish(status, resHeaders, resBuf, error) {
				const reqText = decodeBody(reqBuf, req.headers["content-encoding"]);
				const resText = decodeBody(resBuf, resHeaders["content-encoding"]);
				const reqJson = parseJson(reqText);
				const resJson = parseJson(resText);
				record({
					kind: "http",
					ts: new Date(started).toISOString(),
					durationMs: Date.now() - started,
					edge: tap.name,
					from: edge.from,
					to: edge.to,
					method: req.method,
					url: req.url,
					target: tap.target,
					status,
					error,
					reqHeaders: safeHeaders(req.headers),
					resHeaders: safeHeaders(resHeaders),
					reqBody: reqText,
					resBody: resText,
					nack: resJson?.message?.ack?.status === "NACK" || undefined,
					ids: extractIds(urlObj, reqJson, reqText, resJson, resText),
				});
			}
		});
	});
	// The api tap's port (80) is still held by an ONIX container published there until
	// dev.js recreates it on 8080, so keep retrying instead of giving up.
	let warned = false;
	server.on("error", (err) => {
		if (err.code === "EADDRINUSE" && tap.api) {
			if (!warned) console.log(`[monitor] port ${tap.listen} busy - api tap will bind once it is free`);
			warned = true;
			return setTimeout(() => server.listen(tap.listen, "0.0.0.0"), 1000);
		}
		console.log(`[monitor] tap ${tap.name} cannot listen on ${tap.listen}: ${err.code}`);
	});
	server.on("listening", () => warned && console.log(`[monitor] api tap listening on ${tap.listen}`));
	server.listen(tap.listen, "0.0.0.0");
}

// -- gRPC tap (recorder) ----------------------------------------------------------
/** Read gRPC frames (1-byte flag, 4-byte length) and decode google.protobuf.BytesValue. */
function decodeGrpcBytesValues(buf) {
	const out = [];
	let off = 0;
	while (off + 5 <= buf.length) {
		const len = buf.readUInt32BE(off + 1);
		let msg = buf.subarray(off + 5, off + 5 + len);
		off += 5 + len;
		if (msg[0] !== 0x0a) continue; // field 1, wire type 2
		let i = 1;
		let size = 0;
		let shift = 0;
		while (i < msg.length) {
			const b = msg[i++];
			size |= (b & 0x7f) << shift;
			if (!(b & 0x80)) break;
			shift += 7;
		}
		out.push(msg.subarray(i, i + size).toString("utf8"));
	}
	return out;
}

function startGrpcTap(tap) {
	let session = null;
	const upstream = () => {
		if (!session || session.closed || session.destroyed) {
			session = http2.connect(tap.target);
			session.on("error", () => {});
		}
		return session;
	};
	const server = http2.createServer();
	server.on("stream", (stream, headers) => {
		const started = Date.now();
		const chunks = [];
		let status = "0";
		let failure;
		const done = () => {
			const events = decodeGrpcBytesValues(Buffer.concat(chunks));
			for (const text of events.length ? events : [""]) {
				const ev = parseJson(text) || {};
				const ad = ev.additionalData || {};
				const ids = {
					transaction_id: ad.transaction_id,
					message_id: ad.message_id,
					session_id: ad.session_id,
					action: ad.action,
					subscriber_url: ad.subscriber_url,
				};
				for (const k of Object.keys(ids)) if (!ids[k]) delete ids[k];
				link(ids.transaction_id, ids.session_id);
				record({
					kind: "grpc",
					ts: new Date(started).toISOString(),
					durationMs: Date.now() - started,
					edge: tap.name,
					from: tap.from,
					to: tap.to,
					method: "gRPC",
					url: headers[":path"],
					target: tap.target,
					status: status === "0" ? 200 : 500,
					grpcStatus: status,
					error: failure,
					note: ad.is_mock === true || ad.is_mock === "true" ? "mock side" : "participant side",
					recordedStatus: ad.status_code,
					reqHeaders: {},
					resHeaders: {},
					reqBody: text,
					resBody: "",
					ids,
				});
			}
		};
		let up;
		try {
			const fwd = {};
			for (const [k, v] of Object.entries(headers)) if (!["host", "connection"].includes(k)) fwd[k] = v;
			up = upstream().request(fwd);
		} catch (err) {
			failure = err.message;
		}
		if (!up) {
			stream.respond({ ":status": 200, "content-type": "application/grpc", "grpc-status": "14" }, { endStream: true });
			status = "14";
			return done();
		}
		let trailers = null;
		stream.on("data", (c) => {
			chunks.push(c);
			up.write(c);
		});
		stream.on("end", () => up.end());
		up.on("response", (h) => {
			if (h["grpc-status"] !== undefined) {
				status = String(h["grpc-status"]);
				stream.respond(h, { endStream: true });
				return;
			}
			stream.respond(h, { waitForTrailers: true });
			stream.on("wantTrailers", () => stream.sendTrailers(trailers || { "grpc-status": "0" }));
		});
		up.on("data", (c) => stream.write(c));
		up.on("trailers", (t) => {
			trailers = t;
			status = String(t["grpc-status"] ?? "0");
		});
		up.on("end", () => {
			if (!stream.destroyed && !stream.closed) stream.end();
			done();
		});
		up.on("error", (err) => {
			failure = err.message;
			status = "14";
			if (!stream.headersSent)
				stream.respond(
					{ ":status": 200, "content-type": "application/grpc", "grpc-status": "14", "grpc-message": "recorder unreachable" },
					{ endStream: true }
				);
			done();
		});
	});
	server.on("error", (err) => console.log(`[grpc tap] cannot listen on ${tap.listen}: ${err.code}`));
	server.listen(tap.listen, "0.0.0.0");
}

// -- logs ---------------------------------------------------------------------------
const ANSI = /\u001b\[[0-9;]*m/g;
function levelOf(text) {
	const m = /"level"\s*:\s*"(\w+)"|\[(ERROR|WARN|INFO|DEBUG)\]|\b(error|warn|warning)\b/i.exec(text);
	const raw = (m && (m[1] || m[2] || m[3]) || "info").toLowerCase();
	return raw.startsWith("warn") ? "warn" : raw === "fatal" ? "error" : raw;
}
function ingestLog(service, line) {
	const text = line.replace(ANSI, "");
	if (!text.trim()) return;
	const ids = idsFromText(text);
	link(ids.transaction_id, ids.session_id);
	push(logs, MAX_LOGS, { id: ++seq, ts: new Date().toISOString(), service, level: levelOf(text), text, ids }, "log");
}

// -- health -------------------------------------------------------------------------
const health = {};
function checkHealth() {
	for (const h of config.health || []) {
		const socket = net.connect({ host: h.host || "127.0.0.1", port: h.port });
		const done = (up) => {
			socket.destroy();
			const prev = health[h.service];
			health[h.service] = { up, port: h.port, checkedAt: new Date().toISOString() };
			if (!prev || prev.up !== up) {
				const data = `event: health\ndata: ${JSON.stringify(health)}\n\n`;
				for (const res of clients) res.write(data);
			}
		};
		socket.setTimeout(800);
		socket.once("connect", () => done(true));
		socket.once("timeout", () => done(false));
		socket.once("error", () => done(false));
	}
}

// -- API + UI -----------------------------------------------------------------------
function matches(item, q) {
	if (!q) return true;
	const ids = item.ids || {};
	if (Object.values(ids).some((v) => v === q)) return true;
	// A session id also matches everything on its transactions.
	if (ids.transaction_id && (txnToSessions.get(ids.transaction_id) || new Set()).has(q)) return true;
	const hay = item.text || `${item.url} ${item.reqBody || ""} ${item.resBody || ""}`;
	return hay.includes(q);
}

function summarizeTraces() {
	const byTxn = new Map();
	for (const r of requests) {
		const t = r.ids && r.ids.transaction_id;
		if (!t) continue;
		let s = byTxn.get(t);
		if (!s) {
			s = { transaction_id: t, first: r.ts, last: r.ts, requests: 0, errors: 0, actions: [], domain: r.ids.domain, version: r.ids.version };
			byTxn.set(t, s);
		}
		s.last = r.ts;
		s.requests += 1;
		if (r.status >= 400 || r.error || r.nack || (r.grpcStatus && r.grpcStatus !== "0")) s.errors += 1;
		if (r.kind === "http" && r.to === "onix" && r.ids.action && s.actions[s.actions.length - 1] !== r.ids.action)
			s.actions.push(r.ids.action);
		s.domain = s.domain || r.ids.domain;
		s.version = s.version || r.ids.version;
	}
	return [...byTxn.values()]
		.map((s) => ({ ...s, sessions: [...(txnToSessions.get(s.transaction_id) || [])] }))
		.sort((a, b) => (a.last < b.last ? 1 : -1));
}

const UI_FILE = path.join(__dirname, "ui.html");
function sendJson(res, body, status = 200) {
	res.writeHead(status, { "content-type": "application/json", "cache-control": "no-store" });
	res.end(JSON.stringify(body));
}

const app = http.createServer((req, res) => {
	const url = new URL(req.url, "http://monitor");
	if (req.method === "POST" && url.pathname === "/ingest/logs") {
		let body = "";
		req.on("data", (c) => (body += c));
		req.on("end", () => {
			for (const { service, line } of parseJson(body) || []) ingestLog(service, line);
			res.writeHead(204).end();
		});
		return;
	}
	if (url.pathname === "/" || url.pathname === "/index.html") {
		res.writeHead(200, { "content-type": "text/html; charset=utf-8", "cache-control": "no-store" });
		return fs.createReadStream(UI_FILE).pipe(res);
	}
	if (url.pathname === "/api/stream") {
		res.writeHead(200, { "content-type": "text/event-stream", "cache-control": "no-store", connection: "keep-alive" });
		res.write(`event: health\ndata: ${JSON.stringify(health)}\n\n`);
		clients.add(res);
		const ping = setInterval(() => res.write(": ping\n\n"), 15000);
		req.on("close", () => {
			clearInterval(ping);
			clients.delete(res);
		});
		return;
	}
	if (url.pathname === "/api/snapshot") {
		const q = url.searchParams.get("q") || "";
		return sendJson(res, {
			requests: requests.filter((r) => matches(r, q)).slice(-2000),
			logs: logs.filter((l) => matches(l, q)).slice(-4000),
			health,
			edges: [...(config.taps || []), ...(config.grpcTaps || [])].map((t) => ({ name: t.name, from: t.from, to: t.to })),
		});
	}
	if (url.pathname === "/api/traces") return sendJson(res, summarizeTraces());
	if (url.pathname === "/api/trace") {
		const id = url.searchParams.get("id") || "";
		const txns = new Set([id, ...(sessionToTxns.get(id) || [])]);
		const sessions = new Set([id, ...[...txns].flatMap((t) => [...(txnToSessions.get(t) || [])])]);
		const hit = (item) => {
			const ids = item.ids || {};
			return txns.has(ids.transaction_id) || sessions.has(ids.session_id) || ids.message_id === id;
		};
		return sendJson(res, {
			id,
			transactions: [...txns].filter((t) => txnToSessions.has(t) || requests.some((r) => r.ids?.transaction_id === t)),
			sessions: [...sessions].filter((s) => sessionToTxns.has(s)),
			requests: requests.filter(hit),
			logs: logs.filter(hit),
		});
	}
	if (url.pathname === "/api/export") {
		res.writeHead(200, {
			"content-type": "application/json",
			"content-disposition": `attachment; filename="workbench-monitor-${Date.now()}.json"`,
		});
		return res.end(JSON.stringify({ exportedAt: new Date().toISOString(), requests, logs }, null, 1));
	}
	if (req.method === "POST" && url.pathname === "/api/clear") {
		requests.length = 0;
		logs.length = 0;
		txnToSessions.clear();
		sessionToTxns.clear();
		return sendJson(res, { ok: true });
	}
	sendJson(res, { error: "not found" }, 404);
});

app.listen(PORT, "127.0.0.1", () => {
	for (const tap of config.taps || []) startTap(tap);
	if (config.apiTap) startTap({ ...config.apiTap, name: "api-service", api: true });
	for (const tap of config.grpcTaps || []) startGrpcTap(tap);
	checkHealth();
	setInterval(checkHealth, 5000);
	const n = (config.taps || []).length + (config.apiTap ? 1 : 0) + (config.grpcTaps || []).length;
	console.log(`[monitor] UI on http://localhost:${PORT} - ${n} taps`);
});
