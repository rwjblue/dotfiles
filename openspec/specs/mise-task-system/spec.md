# Mise Task System

## Purpose

All automation uses mise file-based tasks. Tasks are executable scripts with metadata directives that mise parses for dependencies, caching, arguments, and environment.

## Requirements

### Requirement: File-based tasks only

All tasks MUST be individual executable files in task directories — never TOML-defined inline tasks. This makes tasks testable, lintable, and version-controllable.

#### Scenario: Creating a new task
- **WHEN** adding automation
- **THEN** create an executable file in the appropriate tasks directory with `#MISE` directives

### Requirement: TypeScript preferred for complex logic

Tasks with argument parsing, JSON manipulation, file system operations, or API calls SHALL use TypeScript (`.ts` extension). Simple wrappers that mostly shell out MUST use bash (no extension).

#### Scenario: TypeScript task setup
- **WHEN** creating a TypeScript task
- **THEN** use `#!/usr/bin/env -S node --experimental-strip-types` shebang, `//[MISE]` directives, and `depends=["global-tasks-npm-install"]`

#### Scenario: Bash task setup
- **WHEN** creating a bash task
- **THEN** use `#!/usr/bin/env bash` shebang, `# -*- mode: sh; sh-shell: bash; -*-` modeline, `#MISE` directives, and `set -euo pipefail`

### Requirement: Global tasks npm dependency management

TypeScript tasks MUST have `node_modules/` for type checking. The hidden `global-tasks-npm-install` task SHALL handle this automatically via `sources`/`outputs` caching — it only runs `npm install` when `package.json` or `package-lock.json` change.

#### Scenario: Adding an npm dependency for tasks
- **WHEN** a TypeScript task needs a new npm package
- **THEN** add it to `packages/mise/tasks/package.json` and run `npm install`; all TS tasks automatically get it via their `depends=["global-tasks-npm-install"]`

### Requirement: Task naming by directory structure

Task names SHALL be derived from their file path: subdirectories create namespaced names with `:` separators. Known file extensions MUST be stripped.

#### Scenario: Namespaced task
- **WHEN** a file exists at `tasks/openspec/init.ts`
- **THEN** the task is named `openspec:init`

### Requirement: USAGE directives for arguments and flags

Arguments and flags MUST use `#USAGE` (bash) or `//[USAGE]` (TypeScript) directives. Values SHALL be accessible as `$usage_<name>` environment variables, with hyphens converted to underscores.

#### Scenario: Flag with value
- **WHEN** a task defines `#USAGE flag "--tools <tools>" help="..."`
- **THEN** the value is accessible as `$usage_tools` (bash) or `process.env.usage_tools` (TypeScript)

#### Scenario: Boolean flag
- **WHEN** a task defines `#USAGE flag "--force" help="..."`
- **THEN** the value is `"true"` when passed, empty/undefined otherwise

### Requirement: Global vs local task separation

Global tasks in `packages/mise/tasks/` SHALL be available everywhere (symlinked to `~/.config/mise/tasks/`). Work-specific tasks MUST go in `local-packages/mise/tasks/` and are included via `task_config.includes` in `config.local.toml`.

#### Scenario: Adding a work-specific task
- **WHEN** a task contains work-specific logic or credentials
- **THEN** place it in `local-packages/mise/tasks/` with its own `global-local-packages-tasks-npm-install` dependency for TypeScript tasks

### Requirement: Template variables in directives

`#MISE` directives SHALL support Tera template variables: `{{cwd}}` for current working directory, `{{config_root}}` for project/home root, `{{vars.name}}` for mise variables, `{{env.VAR}}` for environment variables.

#### Scenario: Task runs in caller's directory
- **WHEN** a task should execute in the directory where the user invoked it
- **THEN** set `#MISE dir="{{cwd}}"`

### Requirement: Sources/outputs caching

Tasks with `sources` and `outputs` directives SHALL use mise's caching: the task MUST be skipped if outputs are newer than sources. Paths resolve from `config_root`.

#### Scenario: Cached npm install
- **WHEN** `global-tasks-npm-install` has `sources=["package.json", "package-lock.json"]` and `outputs=["node_modules/.package-lock.json"]`
- **THEN** mise skips the task when `node_modules` is up to date
