#!/usr/bin/env node
/**
 * Pre-install bootstrap for the npm projects inside automation-frontend, and for
 * automation-mock-playground-service (Studio live sessions run there).
 *
 * npm 11+ refuses to run a dependency's install script unless it is pre-approved.
 * The frontend needs esbuild's postinstall (Vite will not run without the esbuild
 * binary) and fsevents' (macOS file watching); the backend needs the same two (vitest
 * pulls esbuild, nodemon uses fsevents) plus protobufjs and es5-ext, which arrive via
 * the OpenTelemetry stack. npm only accepts that approval from package.json or .npmrc
 * -- the `--allow-scripts` CLI flag is rejected for project-scoped installs -- and
 * `npm approve-scripts` writes an "allowScripts" field into package.json, which would
 * dirty the frontend repo.
 *
 * So we write the approvals to each project's .npmrc and register those files in the
 * repo's .git/info/exclude. .git/info/exclude is machine-local and never committed, so
 * the frontend repo stays byte-for-byte pristine and the files cannot be committed by
 * accident.
 *
 * Idempotent; safe to re-run. Runs automatically as part of `npm run setup`.
 */
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");

const PROJECTS = [
	{
		repo: "automation-frontend",
		// Path relative to the repo root -- that is what .git/info/exclude patterns
		// are matched against.
		repoPath: "frontend",
		allow: ["esbuild", "fsevents"],
	},
	{
		repo: "automation-frontend",
		repoPath: "backend",
		// protobufjs and es5-ext come in with @opentelemetry/*; esbuild backs vitest.
		allow: ["esbuild", "fsevents", "protobufjs", "es5-ext"],
	},
	{
		repo: "automation-mock-playground-service",
		repoPath: "",
		// esbuild backs tsx (npm run dev); the rest as for the backend's logger stack.
		allow: ["esbuild", "fsevents", "protobufjs", "es5-ext"],
	},
];

for (const { repo, repoPath, allow } of PROJECTS) {
	if (!fs.existsSync(path.join(ROOT, repo))) continue;
	const npmrc = path.join(ROOT, repo, repoPath, ".npmrc");
	const managed = [
		"# Managed by protocol-playground-v2/scripts/prepare-install.js -- do not commit.",
		"# Pre-approves the install scripts npm 11+ would otherwise block.",
		...allow.map((pkg) => `allow-scripts[]=${pkg}`),
		"allow-scripts-pin=false",
	];

	// Keep any hand-written lines (e.g. a registry auth token) that are already there.
	const existing = fs.existsSync(npmrc) ? fs.readFileSync(npmrc, "utf8").split("\n") : [];
	const preserved = existing.filter(
		(line) => line.trim() && !line.startsWith("#") && !line.startsWith("allow-scripts")
	);
	fs.writeFileSync(npmrc, [...managed, ...preserved].join("\n") + "\n");
	console.log(`  ✓ wrote ${path.relative(ROOT, npmrc)}`);
}

for (const { repo, repoPath } of PROJECTS) {
	const exclude = path.join(ROOT, repo, ".git/info/exclude");
	if (!fs.existsSync(path.dirname(exclude))) {
		if (fs.existsSync(path.join(ROOT, repo)))
			console.warn(`  ! ${repo}/.git not found; skipped the local git exclude`);
		continue;
	}
	const pattern = repoPath ? `${repoPath}/.npmrc` : "/.npmrc";
	const lines = fs.existsSync(exclude) ? fs.readFileSync(exclude, "utf8").split("\n") : [];
	if (lines.some((l) => l.trim() === pattern)) continue;
	fs.appendFileSync(
		exclude,
		`${lines.length && lines[lines.length - 1].trim() !== "" ? "\n" : ""}` +
			`# protocol-playground-v2 local dev: keep the generated .npmrc out of git\n${pattern}\n`
	);
	console.log(`  ✓ excluded ${repo}/${pattern.replace(/^\//, "")} via .git/info/exclude (local only)`);
}
