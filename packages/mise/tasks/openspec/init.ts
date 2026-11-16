#!/usr/bin/env -S node --experimental-strip-types
//[MISE] description="Initialize OpenSpec in the current project"
//[MISE] depends=["global-tasks-npm-install"]
//[MISE] dir="{{cwd}}"
//[USAGE] flag "--track" help="Leave generated files visible to version control"
//[USAGE] flag "--tools <tools>" help="AI tools to configure (e.g. 'all', 'claude', 'claude,cursor')"
//[USAGE] flag "--force" help="Auto-cleanup legacy files without prompting"
//[USAGE] flag "--profile <profile>" help="Override global config profile (core or custom)"

import { execFileSync, type ExecFileSyncOptionsWithStringEncoding } from "node:child_process";
import {
  existsSync,
  mkdirSync,
  readFileSync,
  appendFileSync,
} from "node:fs";
import { dirname, join, relative } from "node:path";

const track = process.env.usage_track === "true";
const tools = process.env.usage_tools ?? "";
const force = process.env.usage_force === "true";
const profile = process.env.usage_profile ?? "";

function resolveRepository(): { root: string; exclude: string } {
  const options: ExecFileSyncOptionsWithStringEncoding = {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "ignore"],
  };
  try {
    return {
      root: execFileSync("git", ["rev-parse", "--show-toplevel"], options).trimEnd(),
      exclude: execFileSync("git", ["rev-parse", "--path-format=absolute", "--git-path", "info/exclude"], options).trimEnd(),
    };
  } catch {
    try {
      const root = execFileSync("jj", ["--ignore-working-copy", "root"], options).trimEnd();
      const gitDir = execFileSync("jj", ["--ignore-working-copy", "git", "root"], options).trimEnd();
      return { root, exclude: join(gitDir, "info", "exclude") };
    } catch {
      throw new Error("OpenSpec needs a Git-backed repository to ignore generated files. Use --track to initialize without local excludes.");
    }
  }
}

const repository = track ? undefined : resolveRepository();
const args = ["init"];
if (tools) args.push("--tools", tools);
if (force) args.push("--force");
if (profile) args.push("--profile", profile);

execFileSync("openspec", args, { stdio: "inherit" });

if (!repository) {
  process.exit(0);
}

const excludePatterns = [
  "/openspec",
  "/.agents/skills/.openspec-target",
  "/.*/skills/openspec-*/",
  "/.*/commands/opsx/",
  "/.*/commands/opsx-*.md",
  "/.*/command/opsx-*.md",
  "/.*/prompts/opsx-*",
  "/.*/workflows/opsx-*.md",
  "/.cospec/openspec/commands/opsx-*.md",
];

const prefix = relative(repository.root, process.cwd()).replace(/[\\*?\[\]]/g, "\\$&");
const excludesFile = repository.exclude;
mkdirSync(dirname(excludesFile), { recursive: true });

// Read existing excludes to avoid duplicates
const existing = existsSync(excludesFile) ? readFileSync(excludesFile, "utf-8") : "";
const existingLines = new Set(existing.split("\n"));

const toAdd = excludePatterns
  .map((pattern) => prefix ? `/${prefix}${pattern}` : pattern)
  .filter((pattern) => !existingLines.has(pattern));

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
