#!/usr/bin/env node
/**
 * Watches automation-mock-runner-lib/src and re-runs scripts/sync-local-lib.js on change,
 * so edits to the lib reach the running Vite dev server without a manual step.
 *
 * Vite reloads the frontend on its own once node_modules/@ondc/automation-mock-runner
 * changes, though a CJS dep change sometimes needs the dev server's dep cache to be
 * re-optimized — if a change does not appear, restart `npm run dev`.
 *
 * Run this alongside `npm run dev` in a second terminal.
 */
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const ROOT = path.resolve(__dirname, "..");
const SRC = path.join(ROOT, "automation-mock-runner-lib/src");
const DEBOUNCE_MS = 300;

let timer = null;
let running = false;
let queued = false;

function sync() {
	if (running) {
		queued = true;
		return;
	}
	running = true;
	try {
		execFileSync(process.execPath, [path.join(__dirname, "sync-local-lib.js")], { stdio: "inherit" });
	} catch {
		// Build/pack errors are already printed; keep watching so the next save can fix them.
	}
	running = false;
	if (queued) {
		queued = false;
		sync();
	}
}

console.log(`  • watching ${path.relative(ROOT, SRC)} -> frontend node_modules (ctrl-c to stop)`);
sync();

fs.watch(SRC, { recursive: true }, (_event, filename) => {
	// Ignore the file the lib's own prebuild step regenerates, or we loop forever.
	if (filename && filename.includes("default-helpers-source")) return;
	clearTimeout(timer);
	timer = setTimeout(sync, DEBOUNCE_MS);
});
