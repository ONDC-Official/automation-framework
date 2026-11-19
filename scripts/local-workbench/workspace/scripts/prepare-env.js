#!/usr/bin/env node
/**
 * Creates the local `.env` files the app needs to boot -- backend, frontend and the
 * mock playground service -- from the `.env.example` files the repos ship.
 *
 * Why this exists: the backend fails hard without env (src/utils/axios.ts throws at
 * import time if any upstream service URL or API_SERVICE_KEY is missing, and
 * @ondc/automation-logger requires NODE_ENV), so `npm run dev` cannot start the
 * backend at all until a .env exists. Rather than make every machine hand-copy two
 * files, we derive them from the checked-in examples and fill the few values that
 * must be generated (session secrets).
 *
 * Every target is gitignored (automation-frontend/backend/.gitignore `*.env`,
 * frontend/.gitignore `.env`, automation-mock-playground-service/.gitignore `.env`),
 * so this never dirties a sub-repo.
 *
 * IDEMPOTENT AND NON-DESTRUCTIVE: an existing .env is never overwritten or edited.
 * Delete it if you want a fresh one. Runs from `npm run setup` and `npm run dev`.
 */
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const ROOT = path.resolve(__dirname, "..");
const secret = () => crypto.randomBytes(32).toString("hex");

const TARGETS = [
	{
		label: "backend",
		dir: path.join(ROOT, "automation-frontend/backend"),
		// Values the example leaves as placeholders and that must be real to boot.
		overrides: {
			SESSION_SECRET: secret,
			DASHBOARD_SESSION_SECRET: secret,
		},
	},
	{
		label: "frontend",
		dir: path.join(ROOT, "automation-frontend/frontend"),
		overrides: {},
	},
	{
		label: "mock",
		dir: path.join(ROOT, "automation-mock-playground-service"),
		// Its example names placeholder hosts; point it at the local stack instead. The
		// example's NODE_ENV line carries an inline comment dotenv would read as part
		// of the value, so it is rewritten too.
		overrides: {
			NODE_ENV: () => "development",
			PORT: () => "5004",
			BASE_URL: () => "http://localhost:5004/mock/playground",
			API_SERVICE_URL: () => "http://localhost:5002",
			CONFIG_SERVICE_URL: () => "http://localhost:5003",
		},
	},
];

let created = 0;
for (const { label, dir, overrides } of TARGETS) {
	const env = path.join(dir, ".env");
	const example = path.join(dir, ".env.example");
	const rel = path.relative(ROOT, env);

	if (fs.existsSync(env)) {
		console.log(`  · ${rel} already exists, left untouched`);
		continue;
	}
	if (!fs.existsSync(example)) {
		console.warn(`  ! no ${path.relative(ROOT, example)}; skipped ${label} .env`);
		continue;
	}

	// Rewrite only the keys in `overrides`, and only where they are already assigned,
	// so the example's comments and every other default survive verbatim.
	const filled = fs
		.readFileSync(example, "utf8")
		.split("\n")
		.map((line) => {
			const match = /^([A-Z0-9_]+)=/.exec(line);
			const value = match && overrides[match[1]];
			return value ? `${match[1]}=${value()}` : line;
		})
		.join("\n");

	fs.writeFileSync(env, filled);
	console.log(`  ✓ created ${rel} from .env.example`);
	created++;
}

if (created) {
	console.log(
		"\n  These are local dev defaults pointing at localhost. Edit them if you need\n" +
			"  real upstream services, GitHub OAuth, or S3 — see the comments in each file."
	);
}
