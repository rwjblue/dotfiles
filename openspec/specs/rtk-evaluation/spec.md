### Requirement: Audit task for RTK version evaluation
The system SHALL provide a `mise run rtk:audit` task that runs a suite of known commands through RTK and captures the compressed output for comparison.

#### Scenario: Audit task runs baseline commands
- **WHEN** `mise run rtk:audit` is run
- **THEN** it executes a predefined set of shell commands (git status, git log, ls, npm test output sample, cargo build output sample) through both `rtk <cmd>` and `rtk proxy <cmd>`, saving both outputs to a timestamped directory

#### Scenario: Audit task reports compression ratios
- **WHEN** the audit completes
- **THEN** it prints a summary table showing each command, raw token count (approximated by word count), compressed token count, and compression ratio

#### Scenario: Audit task diffs against previous baseline
- **WHEN** a previous audit baseline exists
- **THEN** the task diffs the current compressed output against the previous baseline and highlights any changes in what was stripped

### Requirement: RTK evaluation skill for AI-assisted review
The system SHALL provide a Claude Code skill (`rtk-evaluate`) that guides an AI agent through evaluating a new RTK version.

#### Scenario: Skill guides version upgrade evaluation
- **WHEN** the `rtk-evaluate` skill is invoked
- **THEN** it instructs the agent to: check the RTK changelog for the new version, run `mise run rtk:audit`, review the diff output for any concerning changes in compression behavior, and check for new telemetry or permission changes

#### Scenario: Skill checks for security-relevant changes
- **WHEN** evaluating a new RTK version
- **THEN** the skill instructs the agent to specifically look for: new network calls, telemetry changes, new file system access, changes to the hook rewrite logic, and new dependencies

### Requirement: Baseline storage
The system SHALL store audit baselines in `packages/rtk/baselines/` so they are version-controlled and diffable.

#### Scenario: Baseline saved after audit
- **WHEN** `mise run rtk:audit --save-baseline` is run
- **THEN** the compressed outputs are saved to `packages/rtk/baselines/<rtk-version>/` overwriting any previous baseline for that version

#### Scenario: Baselines are committed to dotfiles
- **WHEN** a new baseline is saved
- **THEN** the baseline files are plain text and suitable for git diffing
