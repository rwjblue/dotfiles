# RTK evaluation

## Purpose

Compare RTK releases against recorded output before changing the version pin.

## Requirements

### Requirement: Audit task for RTK version evaluation
The system SHALL provide a `mise run rtk:audit` task that runs a suite of known commands through RTK and captures the compressed output for comparison.

#### Scenario: Audit task runs baseline commands
- **WHEN** `mise run rtk:audit` is run
- **THEN** it executes `git status`, `git log --oneline -20`, `ls -1`, `git diff --stat HEAD~1`, and `git branch -a` through both `rtk <cmd>` and `rtk bypass <cmd>` in a disposable Git repository with fixed commits and working tree changes
- **AND** each probe must succeed and produce output before the audit can compare or save a baseline

#### Scenario: Audit task reports compression ratios
- **WHEN** the audit completes
- **THEN** it prints a summary table showing each command, raw token count (approximated by word count), compressed token count, and compression ratio

#### Scenario: Audit task diffs against previous baseline
- **WHEN** an audit baseline exists for the same fixture
- **THEN** the task diffs the current compressed output against the latest baseline and shows changes in the filtered output

#### Scenario: Auditing a candidate executable
- **WHEN** `mise run rtk:audit --rtk <path>` is run
- **THEN** the task uses that executable for both versions of every probe and reports its version

### Requirement: RTK evaluation skill for AI-assisted review
The system SHALL provide a shared agent skill (`rtk-evaluate`) that guides an AI agent through evaluating a new RTK version.

#### Scenario: Skill guides version upgrade evaluation
- **WHEN** the `rtk-evaluate` skill is invoked
- **THEN** it instructs the agent to check the release notes, compare the candidate OSS executable to the pinned release, and review changes in compression, permissions, or telemetry before updating the mise config and lockfile

#### Scenario: Skill checks for security-relevant changes
- **WHEN** evaluating a new RTK version
- **THEN** the skill instructs the agent to specifically look for: new network calls, telemetry changes, new file system access, changes to the hook rewrite logic, and new dependencies

### Requirement: Baseline storage
The system SHALL store audit baselines in `packages/rtk/baselines/` so they are version-controlled and diffable.

#### Scenario: Baseline saved after audit
- **WHEN** `mise run rtk:audit --save-baseline` is run
- **THEN** the compressed outputs are saved to `packages/rtk/baselines/fixture-v1/<rtk-version>/`, overwriting any previous baseline for that version and fixture

#### Scenario: Baselines are committed to dotfiles
- **WHEN** a new baseline is saved
- **THEN** the baseline files are plain text and suitable for git diffing
