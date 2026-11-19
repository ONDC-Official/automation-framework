#!/usr/bin/env node
/**
 * Installs the LOCAL automation-mock-runner-lib into the frontend's node_modules as
 * @ondc/automation-mock-runner, so the playground runs against our working copy
 * instead of the published npm package.
 *
 * It does this by `npm pack`ing the local lib and extracting the tarball over
 * node_modules/@ondc/automation-mock-runner. The result is byte-identical in shape to
 * a real `npm install` of that version: same `files` whitelist (dist, public, README,
 * LICENSE), a real directory rather than a symlink.
 *
 * Why pack-and-copy instead of `npm link` / a symlink:
 *   Vite only pre-bundles CommonJS dependencies it finds as real directories inside
 *   node_modules. A symlink pointing outside the project root skips dep-optimization,
 *   so rollup sees the lib's raw CJS `__exportStar` and fails named imports with
 *   `"CodeValidator" is not exported by ...`. Copying avoids that entirely and means
 *   the frontend builds here exactly as it does in CI and Docker.
 *
 * Why not npm workspaces or a "file:" dependency:
 *   Both rewrite package.json / package-lock.json. A root workspace install also
 *   discards each sub-repo's lockfile — when we tried it, axios silently resolved
 *   1.13.2 -> 1.20.0 and broke two files that compile fine on main. Each sub-repo
 *   must keep installing from its own lockfile.
 *
 * The mock service (automation-mock-playground-service) gets the same copy when its
 * node_modules exists, so Studio live sessions run the lib's graph engine from our
 * working copy on both sides. It is optional: the frontend alone is enough for the
 * playground.
 *
 * Re-run this after every change to the lib (or use `npm run watch:lib`).
 *
 * Usage:
 *   node scripts/sync-local-lib.js            # build the lib, then install it into the frontend
 *   node scripts/sync-local-lib.js --verify   # assert the frontend has our local build
 *   node scripts/sync-local-lib.js --no-build # skip the lib build, just copy current dist/
 */
const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");

const ROOT = path.resolve(__dirname, "..");
const LIB = path.join(ROOT, "automation-mock-runner-lib");
const UI = path.join(ROOT, "automation-frontend/frontend");
const MOCK = path.join(ROOT, "automation-mock-playground-service");
const destOf = (project) => path.join(project, "node_modules/@ondc/automation-mock-runner");
const stampOf = (project) => path.join(destOf(project), ".local-sync.json");
/** Where the lib is installed: the frontend always, the mock service once it has node_modules. */
const TARGETS = [
	{ name: "frontend", dir: UI, required: true },
	{ name: "mock service", dir: MOCK, required: false },
];

const args = process.argv.slice(2);
const verifyOnly = args.includes("--verify");
const skipBuild = args.includes("--no-build");

function fail(msg) {
	console.error(`\n  ✗ ${msg}\n`);
	process.exit(1);
}

function npm(cwd, ...rest) {
	return execFileSync(process.platform === "win32" ? "npm.cmd" : "npm", rest, {
		cwd,
		stdio: ["ignore", "pipe", "inherit"],
		encoding: "utf8",
	});
}

/** Hash of the lib's shipped build, so --verify can tell a stale copy from a fresh one. */
function fingerprintDist() {
	const dist = path.join(LIB, "dist");
	const hash = require("crypto").createHash("sha256");
	const walk = (dir) => {
		for (const entry of fs.readdirSync(dir, { withFileTypes: true }).sort((a, b) => (a.name < b.name ? -1 : 1))) {
			const full = path.join(dir, entry.name);
			if (entry.isDirectory()) walk(full);
			else hash.update(path.relative(dist, full)).update(fs.readFileSync(full));
		}
	};
	walk(dist);
	return hash.digest("hex").slice(0, 16);
}

/**
 * Make Vite see the lib change. Vite decides whether its pre-bundle
 * (node_modules/.vite/deps) is stale by hashing the lockfile — for npm, the hidden
 * node_modules/.package-lock.json — plus its config, never the dep's contents. Copying
 * a new lib over the old one changes neither, so Vite keeps serving the OLD bundle.
 * Worse, when a running server re-bundles for another reason it keeps the same
 * `?v=<browserHash>` URL (its per-file hash is name-based too), and the browser holds
 * that URL as `immutable` — so the page runs the old lib against new frontend code
 * (seen as "Function schema for match not found").
 *
 * Recording the dist fingerprint in that file changes Vite's hash: the next `vite`
 * start re-optimizes on its own ("lockfile has changed"), and every re-bundle gets a
 * new URL. The file's mtime is restored so npm's view of whether its hidden lockfile
 * is current is unchanged. Deleting node_modules/.vite instead (what this script used
 * to do) is not enough: under a running server it triggers exactly that same-URL
 * re-bundle, and on its own it never changes the URL.
 */
function stampViteLockfile(fingerprint) {
	const file = path.join(UI, "node_modules/.package-lock.json");
	if (!fs.existsSync(file)) return;
	const { atime, mtime } = fs.statSync(file);
	const lock = JSON.parse(fs.readFileSync(file, "utf8"));
	if (lock.localMockRunnerSync === fingerprint) return;
	lock.localMockRunnerSync = fingerprint;
	fs.writeFileSync(file, JSON.stringify(lock, null, 2) + "\n");
	fs.utimesSync(file, atime, mtime);
	console.log("  • marked the change for Vite (restart `npm run dev` if it is running)");
}


/** Whether `dep` resolves from `dir` the way Node would: a node_modules/<dep> on the way up. */
function resolvable(dep, dir) {
	for (let at = dir; ; at = path.dirname(at)) {
		if (fs.existsSync(path.join(at, "node_modules", dep, "package.json"))) return true;
		if (path.dirname(at) === at) return false;
	}
}

/**
 * The project's lockfile pins the PUBLISHED lib's dependencies; our working copy may
 * add one, and the published copy's nested node_modules (deps npm could not hoist) is
 * gone once the package dir is replaced. So any dependency that does not resolve from
 * the installed package is copied, with its own dependencies, from the lib's
 * node_modules into the package's nested node_modules — never into the project's.
 */
function provideMissingDeps(dest) {
	const nested = path.join(dest, "node_modules");
	const queue = Object.keys(JSON.parse(fs.readFileSync(path.join(dest, "package.json"), "utf8")).dependencies || {});
	const copied = [];
	while (queue.length) {
		const dep = queue.shift();
		if (resolvable(dep, dest)) continue;
		const from = path.join(LIB, "node_modules", dep);
		if (!fs.existsSync(from)) fail(`dependency ${dep} is missing in the lib too. Run: npm run install:lib`);
		fs.mkdirSync(path.dirname(path.join(nested, dep)), { recursive: true });
		fs.cpSync(from, path.join(nested, dep), { recursive: true, dereference: true });
		copied.push(dep);
		const pkg = JSON.parse(fs.readFileSync(path.join(from, "package.json"), "utf8"));
		queue.push(...Object.keys(pkg.dependencies || {}));
	}
	return copied;
}

if (!fs.existsSync(path.join(LIB, "package.json"))) fail(`local lib not found at ${LIB}`);

/** Asserts `target` has our current local build; returns false when an optional target is not installed. */
function verifyTarget(target, current) {
	const dest = destOf(target.dir);
	if (!target.required && !fs.existsSync(path.join(target.dir, "node_modules"))) return false;
	if (!fs.existsSync(dest)) fail(`@ondc/automation-mock-runner is not installed in the ${target.name}. Run: npm run setup`);
	if (fs.lstatSync(dest).isSymbolicLink()) {
		fail(`the ${target.name} has a SYMLINK to the lib. Vite will not pre-bundle it and named imports will fail at build time.\n    Fix with: npm run sync:lib`);
	}
	if (!fs.existsSync(stampOf(target.dir))) {
		fail(`the ${target.name} is using the PUBLISHED mock-runner, not our local build.\n    Fix with: npm run sync:lib`);
	}
	const stamp = JSON.parse(fs.readFileSync(stampOf(target.dir), "utf8"));
	if (stamp.fingerprint !== current) {
		fail(`the ${target.name} has a STALE copy of the local lib (built ${stamp.syncedAt}).\n    Fix with: npm run sync:lib`);
	}
	console.log(`  ✓ ${target.name} is using the LOCAL mock-runner-lib (v${stamp.version}, dist ${current})`);
	return true;
}

if (verifyOnly) {
	if (!fs.existsSync(path.join(LIB, "dist/index.js"))) fail("local lib is not built. Run: npm run build:lib");
	const current = fingerprintDist();
	for (const target of TARGETS) verifyTarget(target, current);
	process.exit(0);
}

if (!fs.existsSync(path.join(UI, "node_modules"))) fail("frontend node_modules is missing. Run: npm run install:ui");

if (!skipBuild) {
	console.log("  • building automation-mock-runner-lib ...");
	npm(LIB, "run", "build");
}
if (!fs.existsSync(path.join(LIB, "dist/index.js"))) fail("lib build produced no dist/index.js");

const stage = fs.mkdtempSync(path.join(os.tmpdir(), "mock-runner-sync-"));
try {
	console.log("  • packing local lib ...");
	const tarball = path.join(stage, npm(LIB, "pack", "--silent", "--pack-destination", stage).trim().split("\n").pop());
	execFileSync("tar", ["xzf", tarball, "-C", stage]);

	const version = JSON.parse(fs.readFileSync(path.join(LIB, "package.json"), "utf8")).version;
	const fingerprint = fingerprintDist();
	for (const target of TARGETS) {
		if (!target.required && !fs.existsSync(path.join(target.dir, "node_modules"))) continue;
		const dest = destOf(target.dir);
		// Keep the deps npm nested inside the package: the lockfile put them there.
		const keep = path.join(stage, `nested-${target.name.replace(/\W/g, "-")}`);
		const nested = path.join(dest, "node_modules");
		if (fs.existsSync(nested)) fs.renameSync(nested, keep);
		fs.rmSync(dest, { recursive: true, force: true });
		fs.mkdirSync(path.dirname(dest), { recursive: true });
		fs.cpSync(path.join(stage, "package"), dest, { recursive: true });
		if (fs.existsSync(keep)) fs.renameSync(keep, nested);
		const copied = provideMissingDeps(dest);
		if (copied.length) console.log(`  • ${target.name}: provided ${copied.join(", ")} from the lib (not in its lockfile)`);
		if (target.dir === UI) stampViteLockfile(fingerprint);
		fs.writeFileSync(
			stampOf(target.dir),
			JSON.stringify(
				{
					source: LIB,
					version,
					fingerprint,
					syncedAt: new Date().toISOString(),
					note: "Installed from the local lib by scripts/sync-local-lib.js, NOT from npm.",
				},
				null,
				2
			)
		);
		console.log(`  ✓ ${target.name} now uses the LOCAL mock-runner-lib (v${version})`);
	}
} finally {
	fs.rmSync(stage, { recursive: true, force: true });
}
