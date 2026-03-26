---
name: task
description: Mise taskrunner automation patterns. Use when adding tasks, running commands, or understanding task structure.
user-invocable: false
---

# Mise Task Automation

All automation uses **mise** file-based tasks. Always prefer file-based tasks over TOML-defined tasks — they are easier to test, lint, and version.

## Reference Documentation

When you need more detail on any topic below, fetch the relevant page:

- [Tasks overview](https://mise.jdx.dev/tasks/)
- [Architecture](https://mise.jdx.dev/tasks/architecture.html)
- [Running tasks](https://mise.jdx.dev/tasks/running-tasks.html)
- [File tasks](https://mise.jdx.dev/tasks/file-tasks.html)
- [Task arguments](https://mise.jdx.dev/tasks/task-arguments.html)
- [Task configuration](https://mise.jdx.dev/tasks/task-configuration.html)
- [Templates](https://mise.jdx.dev/tasks/templates.html)
- [Monorepo](https://mise.jdx.dev/tasks/monorepo.html)

## Global vs Project-Local Tasks

There are two scopes for tasks:

### Global tasks

Managed in the dotfiles repo at `packages/mise/tasks/`. The entire `packages/mise/` directory is symlinked to `~/.config/mise/`, so global tasks are available everywhere (e.g., `repo:clone`, `fetch`, `gauth`). When adding a global task, create it in `packages/mise/tasks/` in the dotfiles repo.

The global tasks directory has TypeScript infrastructure already set up — see "TypeScript Tasks" below.

### Local/work-specific global tasks

Work-specific tasks that shouldn't be in the public dotfiles repo go in `local-packages/mise/tasks/`. These are included via `task_config.includes` in `local-packages/mise/config.local.toml` (symlinked as `packages/mise/config.local.toml`) and are available globally alongside the regular global tasks. Use the same conventions (file-based, executable, `#MISE`/`//[MISE]` directives) as regular global tasks.

### Project-local tasks

Placed in one of these directories relative to the project root:

- `mise/tasks/`
- `.mise/tasks/`
- `mise-tasks/`
- `.mise-tasks/`
- `.config/mise/tasks/`

Check which convention a project already uses and follow it.

## Task Naming

Files in the tasks directory become tasks. Subdirectories create namespaced names:

```
mise/tasks/
├── build              → mise run build
├── deploy.ts          → mise run deploy
├── test/
│   ├── unit           → mise run test:unit
│   └── integration    → mise run test:integration
└── repo/
    └── clone          → mise run repo:clone
```

Mise strips known extensions (`.ts`, `.sh`, etc.) from the task name. Files must be executable (`chmod +x`).

## Language Preference

Prefer **TypeScript** (`.ts` extension) for tasks with complex logic, argument parsing, JSON manipulation, or API calls. Use **bash** (extensionless) for simple wrappers and glue scripts that mostly shell out.

## TypeScript Tasks

TypeScript tasks use Node's built-in type stripping — no build step needed. The task file has a `.ts` extension and uses `//[MISE]` for directives (mise parses `//[MISE]` in non-bash files, NOT `//#MISE` or `// MISE`).

### How it works

```typescript
#!/usr/bin/env -S node --experimental-strip-types
//[MISE] description="Sync configuration from API"
//[MISE] depends=["global-tasks-npm-install"]
//[USAGE] arg "<env>" help="Target environment"
//[USAGE] flag "--dry-run" help="Preview changes"

import { readFileSync } from "node:fs";

const env: string = process.env.usage_env!;
const dryRun: boolean = process.env.usage_dry_run === "true";

console.log(`Syncing config for ${env}${dryRun ? " (dry run)" : ""}`);
```

Key points:
- File extension must be `.ts` — Node only strips types from `.ts` files
- Use `//[MISE]` and `//[USAGE]` for directives (the `[brackets]` are required)
- Add `//[MISE] depends=["global-tasks-npm-install"]` when the task uses npm packages (see below)
- After creating or modifying a TS task, always run `npx tsc --noEmit` in the tasks directory to verify types

### Type stripping constraints (`erasableSyntaxOnly`)

- Only type annotations are stripped — no `enum`, `namespace`, or parameter properties
- Imports must use explicit file extensions
- Use `import type` for type-only imports (`verbatimModuleSyntax` enforces this)

### Global tasks TypeScript setup

The global tasks directory (`packages/mise/tasks/`) has this infrastructure:

- **`package.json`** — `"type": "module"`, `@types/node` and `typescript` as dev deps, plus any runtime deps
- **`tsconfig.json`** — strict mode, `erasableSyntaxOnly`, `verbatimModuleSyntax`, `types: ["node"]`
- **`global-tasks-npm-install`** — hidden mise task that auto-runs `npm install` when `package.json`/`package-lock.json` change (uses `sources`/`outputs` caching to skip when up to date)

When a global TS task depends on npm packages, add `//[MISE] depends=["global-tasks-npm-install"]` so deps are installed automatically before the task runs.

To add a new npm dependency: add it to `packages/mise/tasks/package.json` and run `npm install`. Install `@types/*` packages as dev deps when the runtime package lacks built-in types.

### Bootstrapping TypeScript for project-local tasks

To set up TS task support in a project, create these files in the project's task directory:

**`package.json`:**
```json
{
  "private": true,
  "type": "module",
  "devDependencies": {
    "@types/node": "^22.0.0",
    "typescript": "^6.0.0"
  }
}
```

**`tsconfig.json`:**
```json
{
  "compilerOptions": {
    "target": "esnext",
    "module": "nodenext",
    "moduleResolution": "nodenext",
    "types": ["node"],
    "strict": true,
    "noEmit": true,
    "skipLibCheck": true,
    "isolatedModules": true,
    "verbatimModuleSyntax": true,
    "erasableSyntaxOnly": true
  }
}
```

**`local-tasks-npm-install`** (hidden task for auto-installing — example assumes `mise/tasks/` directory):
```bash
#!/usr/bin/env bash
#MISE description="Install npm deps for local tasks"
#MISE hide=true
#MISE sources=["mise/tasks/package.json", "mise/tasks/package-lock.json"]
#MISE outputs=["mise/tasks/node_modules/.package-lock.json"]

set -euo pipefail
cd "$(cd "$(dirname "$0")" && pwd -P)"
npm install
```

Note: `sources`/`outputs` paths always resolve from `config_root` (the project root for local config, `$HOME` for global config). For project-local tasks, prefix paths with the task directory relative to the project root (e.g., `mise/tasks/package.json`, not just `package.json`). The global `global-tasks-npm-install` uses `{{config_root}}/.config/mise/tasks/` because global `config_root` is `$HOME`.

Add `node_modules/` to `.gitignore` for the tasks directory. Then any `.ts` task can use `//[MISE] depends=["local-tasks-npm-install"]` for automatic dependency management.

After setup, run `npm install` once, then verify with `npx tsc --noEmit`.

## Bash Tasks

```bash
#!/usr/bin/env bash
# -*- mode: sh; sh-shell: bash; -*-
#MISE description="Deploy application to target environment"
#MISE depends=["build"]
#MISE alias="d"
#USAGE arg "<environment>" help="Target environment" {
#USAGE   choices "dev" "staging" "prod"
#USAGE }
#USAGE flag "--dry-run" help="Preview without executing"

set -euo pipefail

ENVIRONMENT="${usage_environment}"
DRY_RUN="${usage_dry_run:-false}"

if [[ "$DRY_RUN" == "true" ]]; then
  echo "DRY RUN: Would deploy to $ENVIRONMENT"
else
  echo "Deploying to $ENVIRONMENT..."
fi
```

## #MISE Directives

Configuration comments at the top of the file (after shebang). Use `#MISE` in bash, `//[MISE]` in TypeScript:

| Directive | Example | Purpose |
|-----------|---------|---------|
| `description` | `#MISE description="Build the CLI"` | Shown in `mise tasks` listing |
| `alias` | `#MISE alias="b"` | Short name for the task |
| `depends` | `#MISE depends=["lint", "test"]` | Tasks that must run first |
| `dir` | `#MISE dir="{{cwd}}"` | Execution directory (default: project root) |
| `hide` | `#MISE hide=true` | Hide from `mise tasks` listing |
| `env` | `#MISE env={RUST_BACKTRACE = "1"}` | Task-specific env vars |
| `sources` | `#MISE sources=["src/**/*.rs"]` | Input files for caching |
| `outputs` | `#MISE outputs=["target/debug/mycli"]` | Output files for caching |
| `tools` | `#MISE tools={node = "22"}` | Tools to install/activate |
| `raw` | `#MISE raw=true` | Direct shell I/O (interactive tasks) |
| `quiet` | `#MISE quiet=true` | Suppress mise output |
| `silent` | `#MISE silent=true` | Suppress all output |
| `wait_for` | `#MISE wait_for=["setup"]` | Wait if running, don't trigger |

**Note:** Some formatters convert `#MISE` to `# MISE` which is ignored. Use `# [MISE]` as a workaround. In TypeScript files, always use `//[MISE]`.

## #USAGE Directives (Arguments & Flags)

Arguments and flags use `#USAGE` directives (`//[USAGE]` in TypeScript). Values are accessible as `$usage_<name>` env vars (hyphens become underscores).

### Positional arguments

```bash
#USAGE arg "<name>"                          # Required
#USAGE arg "[name]"                          # Optional
#USAGE arg "<file>" default="config.toml"    # With default
#USAGE arg "<files>" var=#true               # Variadic (multiple values)
#USAGE arg "<level>" {                       # With choices
#USAGE   choices "debug" "info" "warn"
#USAGE }
#USAGE arg "<token>" env="API_TOKEN"         # Fallback to env var
```

### Flags

```bash
#USAGE flag "-f --force"                     # Boolean flag
#USAGE flag "-v --verbose" help="Details"    # With help text
#USAGE flag "-o --output <file>"             # Flag with value
#USAGE flag "--format <fmt>" default="json"  # With default
#USAGE flag "-v --verbose" count=#true       # Repeatable (-vvv)
#USAGE flag "--color" negate="--no-color"    # Negatable
```

### Completions

```bash
#USAGE complete "user" run="command"         # Dynamic completions
```

## Template Variables (Tera)

Available in `#MISE` directives:

- `{{config_root}}` — Project root directory (for global config, this is `$HOME`)
- `{{cwd}}` — Current working directory
- `{{env.VAR}}` — Environment variable

## Running Tasks

```bash
mise tasks                    # List all tasks
mise run <name>               # Run a task
mise run <name> -- <args>     # Pass args after --
```
