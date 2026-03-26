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

### Project-local tasks

Placed in one of these directories relative to the project root:

- `mise/tasks/`
- `.mise/tasks/`
- `mise-tasks/`
- `.mise-tasks/`
- `.config/mise/tasks/`

Check which convention a project already uses and follow it.

## Task Naming

Subdirectories create namespaced task names automatically:

```
mise/tasks/
├── build              → mise run build
├── test/
│   ├── unit           → mise run test:unit
│   └── integration    → mise run test:integration
└── repo/
    └── clone          → mise run repo:clone
```

## Language Preference

Prefer **TypeScript** for tasks where it's reasonable (complex logic, argument parsing, JSON manipulation, API calls). Use Node's built-in type stripping to avoid a build step:

```typescript
#!/usr/bin/env -S node --experimental-strip-types
// @ts-check is unnecessary — this is already .ts-style with type stripping

#MISE description="Example TypeScript task"
```

**Important constraints** with type stripping:
- Only type annotations are stripped — no enums, decorators, or other TS-only runtime features
- Imports must use explicit file extensions
- Use `import type` for type-only imports

Use **bash** for simple tasks (wrappers, glue scripts, tasks that mostly shell out):

```bash
#!/usr/bin/env bash
# -*- mode: sh; sh-shell: bash; -*-
#MISE description="Simple wrapper task"

set -euo pipefail
```

## Creating a File-Based Task

Every file-based task must be:

1. **Executable** — run `chmod +x` after creating
2. **Have a shebang** — determines the interpreter
3. **Have a description** — `#MISE description="..."`

### Minimal bash example

```bash
#!/usr/bin/env bash
#MISE description="Run database migrations"

set -euo pipefail

echo "Running migrations..."
```

### Full example with arguments

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
#USAGE flag "--region <region>" help="AWS region" default="us-east-1"

set -euo pipefail

ENVIRONMENT="${usage_environment}"
REGION="${usage_region}"
DRY_RUN="${usage_dry_run:-false}"

if [[ "$DRY_RUN" == "true" ]]; then
  echo "DRY RUN: Would deploy to $ENVIRONMENT in $REGION"
else
  echo "Deploying to $ENVIRONMENT in $REGION..."
fi
```

### TypeScript example

```typescript
#!/usr/bin/env -S node --experimental-strip-types
//#MISE description="Sync configuration from API"
//#USAGE arg "<env>" help="Target environment"
//#USAGE flag "--dry-run" help="Preview changes"

const env: string = process.env.usage_env!;
const dryRun: boolean = process.env.usage_dry_run === "true";

async function main(): Promise<void> {
  console.log(`Syncing config for ${env}${dryRun ? " (dry run)" : ""}`);
}

main();
```

Note: In TypeScript tasks, `#MISE` and `#USAGE` directives use `//` comment prefix.

## #MISE Directives

Configuration comments at the top of the file (after shebang):

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

**Note:** Some formatters convert `#MISE` to `# MISE`. Use `# [MISE]` as an alternative if needed.

## #USAGE Directives (Arguments & Flags)

Arguments and flags use `#USAGE` directives. Values are accessible as `$usage_<name>` env vars (hyphens become underscores).

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

- `{{config_root}}` — Project directory
- `{{cwd}}` — Current working directory
- `{{env.VAR}}` — Environment variable

## Running Tasks

```bash
mise tasks                    # List all tasks
mise run <name>               # Run a task
mise run <name> -- <args>     # Pass args after --
```
