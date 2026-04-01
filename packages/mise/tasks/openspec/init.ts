#!/usr/bin/env -S node --experimental-strip-types
//[MISE] description="Initialize OpenSpec in the current project"
//[MISE] depends=["global-tasks-npm-install"]
//[MISE] dir="{{cwd}}"
//[USAGE] flag "--track" help="Track files in git instead of adding to .git/info/excludes"
//[USAGE] flag "--tools <tools>" help="AI tools to configure (e.g. 'all', 'claude', 'claude,cursor')"
//[USAGE] flag "--force" help="Auto-cleanup legacy files without prompting"
//[USAGE] flag "--profile <profile>" help="Override global config profile (core or custom)"

import { execSync } from "node:child_process";
import {
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  statSync,
  appendFileSync,
} from "node:fs";
import { dirname, join, relative } from "node:path";

const track = process.env.usage_track === "true";
const tools = process.env.usage_tools ?? "";
const force = process.env.usage_force === "true";
const profile = process.env.usage_profile ?? "";

function walkDir(dir: string): Set<string> {
  const results = new Set<string>();
  if (!existsSync(dir)) return results;

  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.name === ".git") continue;
    const fullPath = join(dir, entry.name);
    const rel = relative(".", fullPath);
    results.add(rel);
    if (entry.isDirectory()) {
      for (const child of walkDir(fullPath)) {
        results.add(child);
      }
    }
  }
  return results;
}

// Snapshot before
const before = walkDir(".");

// Build and run openspec init
const args: string[] = [];
if (tools) args.push("--tools", tools);
if (force) args.push("--force");
if (profile) args.push("--profile", profile);

execSync(`openspec init ${args.join(" ")}`, { stdio: "inherit" });

if (track) {
  process.exit(0);
}

// Snapshot after and find new entries
const after = walkDir(".");
const newEntries: string[] = [];
for (const entry of after) {
  if (!before.has(entry)) {
    newEntries.push(entry);
  }
}
newEntries.sort();

if (newEntries.length === 0) {
  console.log("No new files created; nothing to exclude.");
  process.exit(0);
}

// Build minimal exclude patterns: collapse into parent dirs when they're new
const patterns: string[] = [];

for (const entry of newEntries) {
  // Skip if already covered by a pattern we've added
  if (patterns.some((pat) => entry.startsWith(pat + "/"))) continue;

  const isDir = statSync(entry).isDirectory();
  if (isDir) {
    // Only add if this dir itself is new
    if (!before.has(entry)) {
      patterns.push(entry);
    }
  } else {
    const parent = dirname(entry);
    if (parent === ".") {
      patterns.push(entry);
    } else if (!before.has(parent)) {
      // Parent is new — add parent if not already covered
      if (!patterns.some((pat) => parent === pat || parent.startsWith(pat + "/"))) {
        patterns.push(parent);
      }
    } else {
      patterns.push(entry);
    }
  }
}

const excludesFile = ".git/info/excludes";
mkdirSync(dirname(excludesFile), { recursive: true });

// Read existing excludes to avoid duplicates
const existing = existsSync(excludesFile) ? readFileSync(excludesFile, "utf-8") : "";
const existingLines = new Set(existing.split("\n"));

const toAdd = patterns.filter((p) => !existingLines.has(`/${p}`));

if (toAdd.length === 0) {
  console.log(`All patterns already in ${excludesFile}; nothing to add.`);
  process.exit(0);
}

const block = `\n# OpenSpec\n${toAdd.map((p) => `/${p}`).join("\n")}\n`;
appendFileSync(excludesFile, block);

console.log(`Added to ${excludesFile}:`);
for (const p of toAdd) {
  console.log(`  /${p}`);
}
