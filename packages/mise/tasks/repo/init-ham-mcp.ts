#!/usr/bin/env -S node --experimental-strip-types
//[MISE] description="Bootstrap repo-local ham MCP config for Claude Code and Codex"
//[MISE] depends=["global-tasks-npm-install"]
//[USAGE] arg "[repo_path]" help="Target repository path (defaults to current directory)"
//[USAGE] flag "--force" help="Replace existing managed ham MCP entries instead of only adding missing ones"

import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { spawnSync } from "node:child_process";

const repoPath = resolve(process.env.usage_repo_path ?? process.cwd());
const force = process.env.usage_force === "true";

const mcpJsonPath = resolve(repoPath, ".mcp.json");
const codexConfigPath = resolve(repoPath, ".codex/config.toml");
const agentsPath = resolve(repoPath, "AGENTS.md");
const miseConfigPath = resolve(repoPath, "mise/config.toml");

const hamAgentsBegin = "<!-- codex: ham-mcp begin -->";
const hamAgentsEnd = "<!-- codex: ham-mcp end -->";

const hamServers = {
  pota: { command: "pota-mcp" },
  sota: { command: "sota-mcp" },
  solar: { command: "solar-mcp" },
  wspr: { command: "wspr-mcp" },
  qrz: { command: "qrz-mcp" },
  lotw: { command: "lotw-mcp" },
} as const;

type HamServerName = keyof typeof hamServers;
type HamToolName = `pipx:${(typeof hamServers)[HamServerName]["command"]}` | "pipx:qso-graph-auth";

const hamTools: Record<HamToolName, "latest"> = {
  "pipx:pota-mcp": "latest",
  "pipx:sota-mcp": "latest",
  "pipx:solar-mcp": "latest",
  "pipx:wspr-mcp": "latest",
  "pipx:qrz-mcp": "latest",
  "pipx:lotw-mcp": "latest",
  "pipx:qso-graph-auth": "latest",
};

const agentsSnippet = `${hamAgentsBegin}
## Ham Radio MCP Guidance

- Use the configured ham radio MCP servers when they are relevant to the task.
- Prefer \`qrz\` and \`lotw\` for callsign, logbook, and award verification workflows.
- Prefer \`pota\`, \`sota\`, \`solar\`, and \`wspr\` for park, summit, propagation, and band-condition questions.
- Do not put credentials in repo files. Authentication should be handled through the local OS keychain via \`qso-auth\`.
${hamAgentsEnd}
`;

function writeFile(path: string, content: string): void {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, content);
  console.log(`Wrote ${path}`);
}

function formatManagedTomlSection(name: HamServerName): string {
  return `[mcp_servers.${name}]
command = "${hamServers[name].command}"`;
}

function mergeMcpJson(): void {
  const nextConfig: { mcpServers: Record<string, { command?: string }> } = {
    mcpServers: {},
  };

  if (existsSync(mcpJsonPath)) {
    const currentConfig = JSON.parse(readFileSync(mcpJsonPath, "utf8")) as {
      mcpServers?: Record<string, { command?: string }>;
    };
    nextConfig.mcpServers = { ...(currentConfig.mcpServers ?? {}) };
  }

  for (const [name, server] of Object.entries(hamServers)) {
    if (!(name in nextConfig.mcpServers) || force) {
      nextConfig.mcpServers[name] = { command: server.command };
    }
  }

  writeFile(mcpJsonPath, `${JSON.stringify(nextConfig, null, 2)}\n`);
}

function mergeMiseConfig(): void {
  if (existsSync(miseConfigPath)) {
    let nextContent = readFileSync(miseConfigPath, "utf8");
    const sectionPattern = /(?:^|\n)\[tools\]\n[\s\S]*?(?=\n\[|$)/;
    const match = nextContent.match(sectionPattern);

    if (match) {
      const section = match[0];
      const sectionStart = match.index ?? 0;
      const lines = section.split("\n");
      const mergedLines: string[] = [];
      const existingHamTools = new Set<string>();

      for (const line of lines) {
        const matchingTool = (Object.keys(hamTools) as HamToolName[]).find((tool) =>
          line.trimStart().startsWith(`"${tool}"`),
        );

        if (!matchingTool) {
          mergedLines.push(line);
          continue;
        }

        existingHamTools.add(matchingTool);
        if (force) {
          mergedLines.push(`"${matchingTool}" = "${hamTools[matchingTool]}"`);
        } else {
          mergedLines.push(line);
        }
      }

      for (const [tool, version] of Object.entries(hamTools)) {
        if (!existingHamTools.has(tool)) {
          mergedLines.push(`"${tool}" = "${version}"`);
        }
      }

      const mergedSection = `${mergedLines.join("\n").trimEnd()}\n`;
      nextContent = `${nextContent.slice(0, sectionStart)}${mergedSection}${nextContent.slice(sectionStart + match[0].length)}`;
    } else {
      const toolLines = Object.entries(hamTools)
        .map(([tool, version]) => `"${tool}" = "${version}"`)
        .join("\n");
      const trimmed = nextContent.trimEnd();
      nextContent = trimmed.length > 0 ? `${trimmed}\n\n[tools]\n${toolLines}\n` : `[tools]\n${toolLines}\n`;
    }

    writeFile(miseConfigPath, nextContent);
    return;
  }

  writeFile(
    miseConfigPath,
    `#:schema https://mise.jdx.dev/schema/mise.json\n\n[tools]\n${Object.entries(hamTools)
      .map(([tool, version]) => `"${tool}" = "${version}"`)
      .join("\n")}\n`,
  );
}

function upsertManagedCodexSection(content: string, name: HamServerName): string {
  const managedSection = formatManagedTomlSection(name);
  const escapedHeader = `\\[mcp_servers\\.${name}\\]`;
  const sectionPattern = new RegExp(
    `(?:^|\\n)${escapedHeader}\\n[\\s\\S]*?(?=\\n\\[|$)`,
  );
  const hasSection = sectionPattern.test(content);

  if (hasSection) {
    if (!force) {
      return content;
    }

    return content.replace(sectionPattern, `\n${managedSection}\n`);
  }

  const trimmed = content.trimEnd();
  if (trimmed.length === 0) {
    return `${managedSection}\n`;
  }

  return `${trimmed}\n\n${managedSection}\n`;
}

function mergeCodexConfig(): void {
  let nextContent = existsSync(codexConfigPath) ? readFileSync(codexConfigPath, "utf8") : "";

  for (const name of Object.keys(hamServers) as HamServerName[]) {
    nextContent = upsertManagedCodexSection(nextContent, name);
  }

  writeFile(codexConfigPath, nextContent);
}

function detectExistingQsoAuthPersona(): { hasPersona: boolean | null; error: string | null } {
  const result = spawnSync("mise", ["exec", "--", "qso-auth", "persona", "list"], {
    cwd: repoPath,
    encoding: "utf8",
  });

  if (result.status !== 0) {
    const stderr = result.stderr.trim();
    return {
      hasPersona: null,
      error: stderr.length > 0 ? stderr : "Command exited non-zero without stderr output.",
    };
  }

  return {
    hasPersona: !result.stdout.includes("(no personas)"),
    error: null,
  };
}

mergeMiseConfig();
mergeMcpJson();
mergeCodexConfig();

if (existsSync(agentsPath)) {
  const agentsContent = readFileSync(agentsPath, "utf8");
  if (agentsContent.includes(hamAgentsBegin)) {
    if (force) {
      const escapedBegin = hamAgentsBegin.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      const escapedEnd = hamAgentsEnd.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      const blockPattern = new RegExp(`${escapedBegin}[\\s\\S]*?${escapedEnd}\\n?`, "m");
      writeFileSync(agentsPath, agentsContent.replace(blockPattern, agentsSnippet));
      console.log(`Updated ham MCP guidance in ${agentsPath}`);
    } else {
      console.log("AGENTS.md already contains ham MCP guidance");
    }
  } else {
    const prefix = agentsContent.endsWith("\n") ? "\n" : "\n\n";
    writeFileSync(agentsPath, `${agentsContent}${prefix}${agentsSnippet}`);
    console.log(`Appended ham MCP guidance to ${agentsPath}`);
  }
} else {
  writeFileSync(agentsPath, agentsSnippet);
  console.log(`Wrote ${agentsPath}`);
}

const trustResult = spawnSync("mise", ["trust", miseConfigPath], {
  cwd: repoPath,
  stdio: "inherit",
});

if (trustResult.status !== 0) {
  process.exit(trustResult.status ?? 1);
}

const installResult = spawnSync("mise", ["install"], {
  cwd: repoPath,
  stdio: "inherit",
});

if (installResult.status !== 0) {
  process.exit(installResult.status ?? 1);
}

console.log("");
console.log(`Bootstrap complete for ${repoPath}`);
console.log("Next steps:");
console.log("  1. Review mise/config.toml, .mcp.json, and .codex/config.toml");
console.log("  2. Set up QRZ/LoTW credentials in the OS keychain with qso-auth");
console.log("  3. Start Claude Code or Codex from this repository");

const qsoAuthState = detectExistingQsoAuthPersona();
const hasExistingPersona = qsoAuthState.hasPersona;

if (hasExistingPersona === true) {
  console.log("");
  console.log("Existing qso-auth persona detected; skipping credential setup commands.");
  console.log("Verify current keychain state with:");
  console.log("```bash");
  console.log("qso-auth creds doctor");
  console.log("```");
} else if (hasExistingPersona === false) {
  console.log("");
  console.log("Credential setup commands:");
  console.log("```bash");
  console.log("qso-auth persona add \\");
  console.log("  --name personal \\");
  console.log("  --callsign N1RWJ \\");
  console.log("  --start 2025-08-26 \\");
  console.log("  --providers qrz qrz_logbook lotw");
  console.log("");
  console.log("qso-auth persona set-credential \\");
  console.log("  --persona personal \\");
  console.log("  --provider qrz \\");
  console.log("  --username N1RWJ \\");
  console.log("  --password '...'");
  console.log("");
  console.log("qso-auth persona set-credential \\");
  console.log("  --persona personal \\");
  console.log("  --provider qrz_logbook \\");
  console.log("  --username N1RWJ \\");
  console.log("  --api-key '...'");
  console.log("");
  console.log("qso-auth persona set-credential \\");
  console.log("  --persona personal \\");
  console.log("  --provider lotw \\");
  console.log("  --username N1RWJ \\");
  console.log("  --password '...'");
  console.log("```");
} else {
  console.log("");
  console.log("Could not determine qso-auth credential state automatically.");
  console.log("Command attempted:");
  console.log("```bash");
  console.log("mise exec -- qso-auth persona list");
  console.log("```");
  if (qsoAuthState.error) {
    console.log("Command error:");
    console.log("```text");
    console.log(qsoAuthState.error);
    console.log("```");
  }
  console.log("Check with:");
  console.log("```bash");
  console.log("qso-auth persona list");
  console.log("qso-auth creds doctor");
  console.log("```");
}
