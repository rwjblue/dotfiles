#!/usr/bin/env -S node --experimental-strip-types
//[MISE] description="Initialize OpenSpec in the current project"
//[MISE] depends=["global-tasks-npm-install"]
//[MISE] dir="{{cwd}}"
//[USAGE] flag "--track" help="Track files in git instead of adding to .git/info/exclude"
//[USAGE] flag "--tools <tools>" help="AI tools to configure (e.g. 'all', 'claude', 'claude,cursor')"
//[USAGE] flag "--force" help="Auto-cleanup legacy files without prompting"
//[USAGE] flag "--profile <profile>" help="Override global config profile (core or custom)"

import { execSync } from "node:child_process";
import {
  existsSync,
  mkdirSync,
  readFileSync,
  appendFileSync,
} from "node:fs";
import { dirname } from "node:path";

const track = process.env.usage_track === "true";
const tools = process.env.usage_tools ?? "";
const force = process.env.usage_force === "true";
const profile = process.env.usage_profile ?? "";

// Build and run openspec init
const args: string[] = [];
if (tools) args.push("--tools", tools);
if (force) args.push("--force");
if (profile) args.push("--profile", profile);

execSync(`openspec init ${args.join(" ")}`, { stdio: "inherit" });

if (track) {
  process.exit(0);
}

const excludePatterns = [
  "/openspec",
  "/.codeagent/commands/opsx/",
  "/.codex/skills/openspec-*/",
  "/.cursor/commands/opsx-*.md",
  "/.cursor/skills/openspec-*/",
  "/.github/prompts/opsx-*",
  "/.github/skills/openspec-*/",
];

const excludesFile = ".git/info/exclude";
mkdirSync(dirname(excludesFile), { recursive: true });

// Read existing excludes to avoid duplicates
const existing = existsSync(excludesFile) ? readFileSync(excludesFile, "utf-8") : "";
const existingLines = new Set(existing.split("\n"));

const toAdd = excludePatterns.filter((p) => !existingLines.has(p));

if (toAdd.length === 0) {
  console.log(`All patterns already in ${excludesFile}; nothing to add.`);
  process.exit(0);
}

const block = `\n# OpenSpec\n${toAdd.join("\n")}\n`;
appendFileSync(excludesFile, block);

console.log(`Added to ${excludesFile}:`);
for (const p of toAdd) {
  console.log(`  ${p}`);
}
