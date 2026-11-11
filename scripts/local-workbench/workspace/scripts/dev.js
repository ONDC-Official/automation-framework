#!/usr/bin/env node
/**
 * Runs the whole local stack with one command: Redis, the mock playground service,
 * the backend API, and the Vite dev server, with prefixed output and a single Ctrl-C
 * that stops all of them.
 *
 * Why not a dependency like concurrently? This root package.json deliberately
 * declares no dependencies (see its description) so the workspace root never gets a
 * node_modules or a lockfile of its own. node:child_process covers everything we need.
 *
 * What it manages, and why each piece is here:
 *
 *   redis     The backend mounts its express-session store on Redis at import time
 *             (src/app.ts), so sessions and anything auth-shaped fail without it. If
 *             nothing is already listening on REDIS_HOST:REDIS_PORT we start a
 *             throwaway in-memory instance (--save '' --appendonly no) as a CHILD of
 *             this process, so it dies with it and leaves no dump.rdb or launch agent
 *             behind. An already-running Redis (brew services, Docker, a remote host)
 *             is detected and left alone.
 *   mock      automation-mock-playground-service (nodemon + tsx) on PORT from its .env
 *             (5004). It runs live playground sessions -- v1's and Studio's graph-v2
 *             ones -- and is started whenever the backend is, once that repo has a
 *             node_modules (`npm run install:mock`). The backend is pointed at it by
 *             passing MOCK_SERVICE=http://localhost:<port>/mock in the backend's
 *             environment: dotenv never overrides a variable that is already set, so
 *             backend/.env is left untouched. The `/mock` suffix matters -- the backend
 *             builds `${MOCK_SERVICE}/playground/...` and the service mounts its routes
 *             under /mock. Outbound calls still go to the external api-service.
 *   backend   automation-frontend/backend, nodemon + ts-node on PORT from its .env
 *             (4000 by default). The playground itself does not need it -- mock
 *             execution is entirely client-side -- but the rest of the app does, and
 *             promoting a playground config into a live flow session goes through it.
 *   frontend  automation-frontend/frontend, `vite --host` on 5173.
 *
 * The local workbench -- what scenario testing needs end to end, started whenever the
 * backend is, each piece only once it has been cloned and set up (see
 * "Running the whole workbench locally" in CLAUDE.md); a missing piece is skipped with
 * a warning, and anything already listening on its port is left alone:
 *
 *   mongo     Docker container `wb-mongo` (mongo:7) on 27017, for automation-db. Created
 *             on first run, `docker start`ed after that, so its data survives restarts.
 *   db        automation-db (`npm run dev`) on 5001.
 *   registry  scripts/local-registry.js on 5010: a stand-in registry /lookup that answers
 *             with the ONIX build's own SIGNING_PUBLIC, so signatures verify offline.
 *   recorder  automation-recorder-service, a Go binary built into .local/bin (rebuilt when
 *             its sources change), gRPC 8089 / HTTP 8090. Not optional: it is what writes
 *             each transaction's apiList, without which every step after the first fails.
 *   report    automation-report-service (`npm run dev`) on 5005, for Generate Report.
 *   onix      the ONIX api-service generated into
 *             automation-api-service-generator/build-output, via `docker compose up -d`
 *             on its .env PORT. It dials Redis and the recorder at boot and exits if
 *             either is down, so it starts after both. Its debug-level log lines are
 *             dropped from the output.
 *
 * Containers are not children, so they are tracked separately: the ones this process
 * started are `docker stop`ped on shutdown; ones that were already running are not.
 *
 *   monitor   scripts/monitor/server.js, UI on http://localhost:4400. Started first (with
 *             the backend), it records every inter-service request end to end and every
 *             log line, correlated by transaction_id / session_id / message_id. Each
 *             caller->callee edge gets its own tap port (47xx) and the caller's upstream
 *             URL is rewritten to it through env vars only -- no .env file is edited.
 *             The api-service URL is baked into payloads, so for it the monitor takes the
 *             ONIX port (80) itself and the container is published on 127.0.0.1:8080
 *             instead, with its self-calls routed back out through the host. ONIX's gRPC
 *             reports to the recorder go through a decoding tap (4720). All log lines
 *             printed here are also forwarded to it. `--no-monitor` wires everything
 *             directly, as before.
 *
 * Child processes are spawned detached so each gets its own process group, and we
 * signal the group (kill -pid): `npm run dev` is a shell wrapper around nodemon which
 * then spawns ts-node, and killing only the npm pid would orphan the server holding
 * port 4000.
 *
 * Flags:
 *   --backend-only / --be     skip the Vite dev server
 *   --frontend-only / --ui    skip Redis and the backend
 *   --no-redis                never start Redis (use when you manage it yourself)
 *   --no-mock                 don't start the mock service; backend/.env's MOCK_SERVICE
 *                             is used as is
 *   --no-workbench            skip mongo, db, registry, recorder, report and onix
 *   --no-monitor              don't start the monitor; services talk to each other directly
 *
 * The local-lib freshness check (scripts/sync-local-lib.js --verify) is run by the
 * npm script, not here, so `npm run dev` still fails fast on a stale mock-runner.
 */
const { spawn, spawnSync } = require("child_process");
const fs = require("fs");
const http = require("http");
const net = require("net");
const os = require("os");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const BACKEND = path.join(ROOT, "automation-frontend/backend");
const FRONTEND = path.join(ROOT, "automation-frontend/frontend");
const MOCK = path.join(ROOT, "automation-mock-playground-service");
const DB = path.join(ROOT, "automation-db");
const RECORDER = path.join(ROOT, "automation-recorder-service");
const REPORT = path.join(ROOT, "automation-report-service");
const ONIX = path.join(ROOT, "automation-api-service-generator/build-output");
const RECORDER_BIN = path.join(ROOT, ".local/bin/automation-recorder");
const MONGO_CONTAINER = "wb-mongo";

const argv = process.argv.slice(2);
const has = (...names) => names.some((n) => argv.includes(n));
const backendOnly = has("--backend-only", "--be");
const frontendOnly = has("--frontend-only", "--ui", "--frontend");
const wantBackend = !frontendOnly;
const wantFrontend = !backendOnly;
const wantRedis = wantBackend && !has("--no-redis");
const wantMock = wantBackend && !has("--no-mock");
const wantWorkbench = wantBackend && !has("--no-workbench");
let wantMonitor = wantBackend && !has("--no-monitor");
const MONITOR_PORT = 4400;
const ONIX_MONITORED_PORT = 8080; // where the ONIX container is published when the monitor fronts it

const C = {
	reset: "\u001b[0m",
	dim: "\u001b[2m",
	green: "\u001b[32m",
	yellow: "\u001b[33m",
	blue: "\u001b[34m",
	magenta: "\u001b[35m",
	cyan: "\u001b[36m",
	red: "\u001b[31m",
	gray: "\u001b[90m",
};
const note = (msg) => console.log(`${C.dim}[dev]${C.reset} ${msg}`);
const warn = (msg) => console.log(`${C.yellow}[dev]${C.reset} ${msg}`);

/** Read a key out of a .env file without pulling in dotenv. */
function envValue(file, key, fallback) {
	if (!fs.existsSync(file)) return fallback;
	const match = new RegExp(`^${key}=(.*)$`, "m").exec(fs.readFileSync(file, "utf8"));
	const value = match && match[1].trim();
	return value ? value : fallback;
}

function portOpen(host, port, timeout = 400) {
	return new Promise((resolve) => {
		const socket = net.connect({ host, port });
		const done = (result) => {
			socket.destroy();
			resolve(result);
		};
		socket.setTimeout(timeout);
		socket.once("connect", () => done(true));
		socket.once("timeout", () => done(false));
		socket.once("error", () => done(false));
	});
}

async function waitForPort(host, port, timeoutMs) {
	const deadline = Date.now() + timeoutMs;
	while (Date.now() < deadline) {
		if (shuttingDown) return false;
		if (await portOpen(host, port)) return true;
		await new Promise((r) => setTimeout(r, 500));
	}
	return false;
}

function commandExists(command) {
	return spawnSync("sh", ["-c", `command -v ${command}`], { stdio: "ignore" }).status === 0;
}

/** Newest mtime of the files directly in `dir` that `match` accepts. */
function newestMtime(dir, match) {
	let newest = 0;
	for (const name of fs.readdirSync(dir)) {
		if (!match(name)) continue;
		newest = Math.max(newest, fs.statSync(path.join(dir, name)).mtimeMs);
	}
	return newest;
}

// -- process supervision -----------------------------------------------------
const children = [];
// Docker containers this process started (not children): stopped on shutdown.
const startedContainers = [];
let shuttingDown = false;

/** Prefix every line of a child's output with its label; `filter` drops lines. */
function pipeOutput(child, name, color, filter) {
	const label = `${color}[${name}]${C.reset} `;
	for (const stream of [child.stdout, child.stderr]) {
		let buffer = "";
		const emit = (line) => {
			if (filter && !filter(line)) return;
			process.stdout.write(label + line + "\n");
			forwardToMonitor(name, line);
		};
		stream.setEncoding("utf8");
		stream.on("data", (chunk) => {
			buffer += chunk;
			const lines = buffer.split("\n");
			buffer = lines.pop();
			for (const line of lines) emit(line);
		});
		stream.on("end", () => {
			if (buffer) emit(buffer);
		});
	}
}

/** A one-shot command (a build, `docker compose up -d`): resolves to its exit code. */
function runStep({ name, color, command, args, cwd, env }) {
	return new Promise((resolve) => {
		const child = spawn(command, args, {
			cwd,
			env: { ...process.env, ...env },
			stdio: ["ignore", "pipe", "pipe"],
		});
		pipeOutput(child, name, color);
		child.on("exit", (code) => resolve(code ?? 1));
		child.on("error", (err) => {
			warn(`${name}: ${err.message}`);
			resolve(1);
		});
	});
}

/** Stop the containers this process started. Synchronous: it runs during shutdown. */
function stopContainers() {
	for (const c of startedContainers.splice(0)) {
		note(`stopping ${c.label}...`);
		spawnSync("docker", c.stopArgs, { cwd: c.cwd, stdio: "ignore" });
	}
}

function run({ name, color, command, args, cwd, env, filter }) {
	if (shuttingDown) return null; // Ctrl-C landed while the stack was still starting
	const child = spawn(command, args, {
		cwd,
		env: { ...process.env, FORCE_COLOR: "1", ...env },
		stdio: ["ignore", "pipe", "pipe"],
		detached: true, // own process group, so we can signal the whole tree
	});
	const entry = { name, child };
	children.push(entry);
	pipeOutput(child, name, color, filter);

	child.on("exit", (code, signal) => {
		entry.exited = true;
		if (shuttingDown) return;
		const how = signal ? `signal ${signal}` : `code ${code}`;
		warn(`${name} exited (${how}) - stopping the rest`);
		shutdown(typeof code === "number" && code !== 0 ? code : 1);
	});
	child.on("error", (err) => {
		entry.exited = true;
		if (shuttingDown) return;
		warn(`${name} failed to start: ${err.message}`);
		shutdown(1);
	});
	return entry;
}

function shutdown(code) {
	if (shuttingDown) return;
	shuttingDown = true;
	for (const { child, exited } of children) {
		if (exited) continue;
		// Negative pid = the whole process group (npm -> nodemon -> ts-node).
		try {
			process.kill(-child.pid, "SIGTERM");
		} catch {
			try {
				child.kill("SIGTERM");
			} catch {}
		}
	}
	stopContainers();
	// Give them a moment to go down cleanly, then stop waiting.
	const timer = setTimeout(() => {
		for (const { child, exited } of children) {
			if (exited) continue;
			try {
				process.kill(-child.pid, "SIGKILL");
			} catch {}
		}
		process.exit(code);
	}, 2500);
	timer.unref();
	const poll = setInterval(() => {
		if (children.every((c) => c.exited)) {
			clearInterval(poll);
			process.exit(code);
		}
	}, 100);
}

for (const signal of ["SIGINT", "SIGTERM"]) {
	process.on(signal, () => {
		console.log("");
		note("shutting down...");
		shutdown(0);
	});
}

// -- monitor -----------------------------------------------------------------
const monitorTaps = [];
const monitorGrpcTaps = [];

/**
 * Route a caller's upstream URL through a monitor tap for the from->to edge and return
 * the URL the caller should use instead (the original when the monitor is off). The
 * path and query are kept byte for byte -- callers append to these strings, and some
 * (the registry) rely on a trailing slash. `callerHost` is how the caller reaches the
 * host (host.docker.internal from inside the ONIX container); `target` overrides where
 * the tap forwards to.
 */
function viaTap(from, to, listen, url, { callerHost = "localhost", target } = {}) {
	if (!wantMonitor || !url) return url;
	const u = new URL(url);
	monitorTaps.push({ name: `${from}->${to}`, from, to, listen, target: target || u.origin });
	return `http://${callerHost}:${listen}${url.slice(u.origin.length)}`;
}

// Every printed line is also sent to the monitor, in small batches, once it is up.
let monitorQueue = [];
let monitorReady = false;
function forwardToMonitor(service, line) {
	if (!wantMonitor) return;
	monitorQueue.push({ service, line });
	if (monitorQueue.length > 5000) monitorQueue.splice(0, monitorQueue.length - 5000);
}
setInterval(() => {
	if (!monitorReady || !monitorQueue.length) return;
	const body = JSON.stringify(monitorQueue);
	monitorQueue = [];
	const req = http.request({
		host: "127.0.0.1",
		port: MONITOR_PORT,
		method: "POST",
		path: "/ingest/logs",
		headers: { "content-type": "application/json", "content-length": Buffer.byteLength(body) },
	});
	req.on("error", () => {});
	req.end(body);
}, 300).unref();

async function startMonitor(health, apiTap) {
	if (await portOpen("127.0.0.1", MONITOR_PORT)) {
		warn(`port ${MONITOR_PORT} is in use - not starting the monitor (its taps would be missing)`);
		return false;
	}
	const config = { port: MONITOR_PORT, taps: monitorTaps, grpcTaps: monitorGrpcTaps, apiTap, health };
	run({
		name: "monitor",
		color: C.gray,
		command: process.execPath,
		args: [path.join(__dirname, "monitor/server.js")],
		env: { MONITOR_CONFIG: JSON.stringify(config) },
	});
	monitorReady = await waitForPort("127.0.0.1", MONITOR_PORT, 10000);
	return monitorReady;
}

// -- local workbench ---------------------------------------------------------
const missing = (what, how) => warn(`${what} is not set up - ${how} (skipped it)`);

async function startMongo() {
	if (await portOpen("127.0.0.1", 27017)) {
		note("something is already on 27017 - assuming it is Mongo");
		return true;
	}
	const exists =
		spawnSync("docker", ["container", "inspect", MONGO_CONTAINER], { stdio: "ignore" })
			.status === 0;
	const args = exists
		? ["start", MONGO_CONTAINER]
		: ["run", "-d", "--name", MONGO_CONTAINER, "-p", "127.0.0.1:27017:27017", "mongo:7"];
	startedContainers.push({ label: MONGO_CONTAINER, stopArgs: ["stop", MONGO_CONTAINER] });
	if ((await runStep({ name: "mongo", color: C.gray, command: "docker", args })) !== 0) {
		warn("could not start Mongo - automation-db will not come up");
		return false;
	}
	note(`${exists ? "started" : "created"} the ${MONGO_CONTAINER} container (stopped on exit)`);
	return waitForPort("127.0.0.1", 27017, 30000);
}

/** Build the recorder into .local/bin when the binary is missing or older than its source. */
async function buildRecorder() {
	const built = fs.existsSync(RECORDER_BIN) ? fs.statSync(RECORDER_BIN).mtimeMs : 0;
	const source = newestMtime(RECORDER, (n) => n.endsWith(".go") || n === "go.mod" || n === "go.sum");
	if (built >= source) return true;
	note("building automation-recorder-service...");
	fs.mkdirSync(path.dirname(RECORDER_BIN), { recursive: true });
	const code = await runStep({
		name: "recorder",
		color: C.red,
		command: "go",
		args: ["build", "-o", RECORDER_BIN, "."],
		cwd: RECORDER,
	});
	return code === 0;
}

async function startWorkbench(redisHost, redisPort, links) {
	const dockerUp =
		commandExists("docker") && spawnSync("docker", ["info"], { stdio: "ignore" }).status === 0;
	if (!dockerUp) warn("Docker is not running - skipping Mongo, automation-db and the ONIX api-service");

	// mongo + automation-db
	const dbEnv = path.join(DB, ".env");
	if (!fs.existsSync(path.join(DB, "node_modules")) || !fs.existsSync(dbEnv)) {
		missing("automation-db", "clone it, `npm ci` in it and give it a .env with MONGO_URI");
	} else if (await portOpen("127.0.0.1", 5001)) {
		note("something is already on 5001 - assuming it is automation-db");
	} else if (dockerUp && (await startMongo())) {
		run({ name: "db", color: C.yellow, command: "npm", args: ["run", "dev"], cwd: DB });
	}

	// stand-in registry: answers lookups with the ONIX build's own public key
	const onixEnv = path.join(ONIX, ".env");
	const signingPublic = envValue(onixEnv, "SIGNING_PUBLIC", "");
	const registryPort = Number(
		(/:(\d+)/.exec(envValue(onixEnv, "IN_HOUSE_REGISTRY", "").replace(/^\w+:\/\//, "")) || [])[1] ||
			5010
	);
	if (!signingPublic) {
		missing("the stand-in registry", "it needs SIGNING_PUBLIC in the ONIX build-output/.env");
	} else if (await portOpen("127.0.0.1", registryPort)) {
		note(`something is already on ${registryPort} - assuming it is the registry`);
	} else {
		run({
			name: "registry",
			color: C.gray,
			command: process.execPath,
			args: [path.join(__dirname, "local-registry.js"), String(registryPort)],
			env: { SIGNING_PUBLIC: signingPublic },
		});
	}

	// recorder: the ONIX build dials it at boot, so it must be up first
	let recorderUp = false;
	if (!fs.existsSync(path.join(RECORDER, "go.mod"))) {
		missing("automation-recorder-service", "clone it into the workspace");
	} else if (await portOpen("127.0.0.1", 8089)) {
		note("something is already on 8089 - assuming it is the recorder");
		recorderUp = true;
	} else if (!commandExists("go")) {
		missing("the recorder", "it needs Go to build");
	} else if (await buildRecorder()) {
		run({
			name: "recorder",
			color: C.red,
			command: RECORDER_BIN,
			args: [],
			cwd: RECORDER,
			env: {
				RECORDER_LISTEN_ADDR: ":8089",
				RECORDER_HTTP_LISTEN_ADDR: ":8090",
				REDIS_ADDR: `${redisHost}:${redisPort}`,
				RECORDER_ENV: "dev",
				RECORDER_SKIP_NO_PUSH: "true",
				RECORDER_DB_BASE_URL: links.recorderDb,
				RECORDER_DB_API_KEY: envValue(dbEnv, "API_SERVICE_KEY", ""),
				RECORDER_DB_ENABLED_ENVS: "",
			},
		});
		recorderUp = await waitForPort("127.0.0.1", 8089, 20000);
	} else {
		warn("the recorder failed to build (skipped it)");
	}

	// report service
	if (!fs.existsSync(path.join(REPORT, "node_modules")) || !fs.existsSync(path.join(REPORT, ".env"))) {
		missing("automation-report-service", "clone it, `npm ci` in it and give it a .env");
	} else if (await portOpen("127.0.0.1", 5005)) {
		note("something is already on 5005 - assuming it is the report service");
	} else {
		run({
			name: "report",
			color: C.cyan,
			command: "npm",
			args: ["run", "dev"],
			cwd: REPORT,
			env: links.reportEnv, // dotenv never overrides these
		});
	}

	// ONIX api-service. With the monitor in front it is published on ONIX_MONITORED_PORT
	// and the monitor owns its usual port, so "something is on the port" says nothing
	// about the container: always `compose up -d`, which recreates it only on a change.
	const onixPort = Number(envValue(onixEnv, "PORT", "0"));
	const onixProbe = links.onixCompose ? ONIX_MONITORED_PORT : onixPort;
	const onixWasRunning =
		dockerUp &&
		spawnSync("docker", ["compose", "ps", "-q", "--status", "running"], { cwd: ONIX, encoding: "utf8" })
			.stdout?.trim().length > 0;
	if (!fs.existsSync(path.join(ONIX, "docker-compose.yml")) || !onixPort) {
		missing(
			"the ONIX api-service",
			"run the generator (IS_ONIX_ENABLED=true `npm start` in automation-api-service-generator)"
		);
	} else if (!links.onixCompose && (await portOpen("127.0.0.1", onixPort))) {
		note(`something is already on ${onixPort} - assuming it is the ONIX api-service`);
	} else if (!dockerUp) {
		// already warned
	} else if (!recorderUp) {
		warn("the recorder is not up, and the ONIX api-service exits without it (skipped it)");
	} else {
		note("starting the ONIX api-service (the first run builds its image - a few minutes)...");
		if (!onixWasRunning)
			startedContainers.push({ label: "the ONIX api-service", stopArgs: ["compose", "stop"], cwd: ONIX });
		const code = await runStep({
			name: "onix",
			color: C.magenta,
			command: "docker",
			args: ["compose", "up", "-d"],
			cwd: ONIX,
			env: links.onixCompose || {}, // interpolated into build-output/docker-compose.yml
		});
		if (code !== 0) {
			warn("`docker compose up` failed for the ONIX api-service");
		} else if (!shuttingDown) {
			// Follow its log as a supervised child: if the container dies, so does the stack.
			run({
				name: "onix",
				color: C.magenta,
				command: "docker",
				args: ["compose", "logs", "-f", "--no-log-prefix", "--tail", "0"],
				cwd: ONIX,
				filter: (line) => !line.includes('"level":"debug"'),
			});
			if (await waitForPort("127.0.0.1", onixProbe, 60000))
				note(
					links.onixCompose
						? `ONIX api-service on ${onixProbe}, fronted by the monitor on ${onixPort}`
						: `ONIX api-service listening on ${onixPort}`
				);
		}
	}
}

// -- main --------------------------------------------------------------------
(async () => {
	// Neither server starts without its .env; create them from the examples if needed.
	require("./prepare-env.js");

	const backendEnvFile = path.join(BACKEND, ".env");
	const backendPort = Number(envValue(backendEnvFile, "PORT", "4000"));
	const redisHost = envValue(backendEnvFile, "REDIS_HOST", "127.0.0.1");
	const redisPort = Number(envValue(backendEnvFile, "REDIS_PORT", "6379"));

	// Before anything is started: exiting later would orphan the children already up.
	if (wantBackend && (await portOpen("127.0.0.1", backendPort))) {
		warn(
			`port ${backendPort} is already in use - another backend is running. ` +
				"Stop it, or run `npm run dev:ui` to start only the frontend."
		);
		process.exit(1);
	}

	if (wantRedis) {
		if (await portOpen(redisHost, redisPort)) {
			note(`Redis already running on ${redisHost}:${redisPort} - leaving it alone`);
		} else if (redisHost !== "127.0.0.1" && redisHost !== "localhost") {
			warn(`Redis at ${redisHost}:${redisPort} is unreachable; sessions will fail`);
		} else {
			run({
				name: "redis",
				color: C.magenta,
				command: "redis-server",
				args: [
					"--port", String(redisPort),
					"--save", "", // no RDB snapshots: nothing to clean up
					"--appendonly", "no",
					"--dir", os.tmpdir(),
				],
			});
			note(`started a throwaway Redis on ${redisPort} (stops with this process)`);
			await waitForPort(redisHost, redisPort, 10000);
		}
	}

	// Each caller's upstream URL, routed through a monitor tap when the monitor runs.
	// Only env vars change (dotenv never overrides a set variable); no .env is edited.
	if (wantMonitor && (await portOpen("127.0.0.1", MONITOR_PORT))) {
		warn(`port ${MONITOR_PORT} is in use - starting without the monitor`);
		wantMonitor = false;
	}
	const onixPort = Number(envValue(path.join(ONIX, ".env"), "PORT", "0"));
	const monitorOnix =
		wantMonitor && wantWorkbench && onixPort > 0 && fs.existsSync(path.join(ONIX, "docker-compose.yml"));
	const mockPort = Number(envValue(path.join(MOCK, ".env"), "PORT", "5004"));
	const backendUrl = `http://localhost:${backendPort}`;
	const fromDocker = { callerHost: "host.docker.internal" };
	const reportEnvFile = path.join(REPORT, ".env");
	const links = {
		recorderDb: viaTap("recorder", "db", 4708, "http://localhost:5001"),
		reportEnv: wantMonitor
			? {
					DATA_BASE_URL: viaTap("report", "db", 4709, envValue(reportEnvFile, "DATA_BASE_URL", "http://localhost:5001")),
					AUTOMATION_BACKEND: viaTap("report", "backend", 4710, envValue(reportEnvFile, "AUTOMATION_BACKEND", backendUrl)),
				}
			: {},
		onixCompose: monitorOnix
			? {
					ONIX_PUBLISH: `127.0.0.1:${ONIX_MONITORED_PORT}`,
					ONIX_SELF_HOST: "host-gateway",
					ONIX_MOCK_SERVER_URL: viaTap("onix", "mock", 4707, `http://localhost:${mockPort}/mock`, fromDocker),
					ONIX_RECORDER_HTTP_URL: viaTap("onix", "recorder", 4712, "http://localhost:8090", fromDocker),
					ONIX_REGISTRY_URL: viaTap("onix", "registry", 4713, "http://localhost:5010/", fromDocker),
					ONIX_RECORDER_GRPC_URL: "host.docker.internal:4720",
				}
			: null,
	};
	if (monitorOnix)
		monitorGrpcTaps.push({ name: "onix->recorder", from: "onix", to: "recorder", listen: 4720, target: "http://127.0.0.1:8089" });
	const mockEnv = wantMonitor
		? { CONFIG_SERVICE_URL: viaTap("mock", "config", 4706, envValue(path.join(MOCK, ".env"), "CONFIG_SERVICE_URL", "")) }
		: {};
	const frontendEnv = wantMonitor
		? { VITE_BACKEND_URL: viaTap("frontend", "backend", 4711, envValue(path.join(FRONTEND, ".env"), "VITE_BACKEND_URL", backendUrl)) }
		: {};
	// The backend reads these from its env first (dotenv does not override them).
	const backendEnv = wantMonitor
		? {
				DB_SERVICE: viaTap("backend", "db", 4702, envValue(backendEnvFile, "DB_SERVICE", "")),
				REPORTING_SERVICE: viaTap("backend", "report", 4703, envValue(backendEnvFile, "REPORTING_SERVICE", "")),
				CONFIG_SERVICE: viaTap("backend", "config", 4704, envValue(backendEnvFile, "CONFIG_SERVICE", "")),
				API_SERVICE: viaTap(
					"backend",
					"onix",
					4705,
					envValue(backendEnvFile, "API_SERVICE", ""),
					monitorOnix ? { target: `http://127.0.0.1:${ONIX_MONITORED_PORT}` } : {}
				),
			}
		: {};
	const backendMockUrl = viaTap("backend", "mock", 4701, `http://localhost:${mockPort}/mock`);

	if (wantMonitor) {
		const health = [
			["frontend", 5173], ["backend", backendPort], ["mock", mockPort],
			["onix", monitorOnix ? ONIX_MONITORED_PORT : onixPort || 80], ["recorder", 8089], ["db", 5001],
			["report", 5005], ["registry", 5010], ["redis", redisPort], ["mongo", 27017],
		].map(([service, port]) => ({ service, port }));
		const apiTap = monitorOnix ? { listen: onixPort, target: `http://127.0.0.1:${ONIX_MONITORED_PORT}` } : null;
		if (await startMonitor(health, apiTap)) note(`monitor UI on http://localhost:${MONITOR_PORT}`);
		else warn("the monitor did not come up - tapped calls between services will fail");
	}

	if (wantWorkbench) await startWorkbench(redisHost, redisPort, links);
	if (shuttingDown) return;

	if (wantMock) {
		const mockUrl = `http://localhost:${mockPort}/mock`;
		if (!fs.existsSync(path.join(MOCK, "node_modules"))) {
			warn(
				"the mock service is not installed - run `npm run install:mock` to have " +
					"live sessions work locally (skipped it)"
			);
		} else if (await portOpen("127.0.0.1", mockPort)) {
			note(`something is already on ${mockPort} - assuming it is the mock service`);
			backendEnv.MOCK_SERVICE = backendMockUrl;
		} else {
			run({
				name: "mock",
				color: C.blue,
				command: "npm",
				args: ["run", "dev"],
				cwd: MOCK,
				env: mockEnv,
			});
			backendEnv.MOCK_SERVICE = backendMockUrl;
		}
		if (backendEnv.MOCK_SERVICE)
			note(`backend MOCK_SERVICE=${backendEnv.MOCK_SERVICE} (overrides backend/.env; real mock ${mockUrl})`);
	}

	if (wantBackend) {
		run({
			name: "backend",
			color: C.cyan,
			command: "npm",
			args: ["run", "dev"],
			cwd: BACKEND,
			env: backendEnv,
		});
	}

	if (wantFrontend) {
		run({
			name: "frontend",
			color: C.green,
			command: "npm",
			args: ["run", "dev"],
			cwd: FRONTEND,
			env: frontendEnv,
		});
	}

	const started = children.map((c) => c.name).join(", ") || "nothing";
	note(`running: ${started}${C.dim} - Ctrl-C stops all of them${C.reset}`);
	if (wantBackend && !wantWorkbench) {
		note(
			`${C.dim}--no-workbench: the backend's API/DB/REPORTING services (backend/.env) ` +
				`are not started here; routes that need them will error until they run${C.reset}`
		);
	}
})();
