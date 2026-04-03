---
name: rtk-evaluate
description: Evaluate an RTK version upgrade for safety and compatibility before updating
---

# RTK Version Evaluation

Use this skill when upgrading RTK to a new version. It guides you through verifying that the new version is safe and doesn't introduce regressions in compression behavior.

## Steps

### 1. Check Current Version

```bash
rtk --version
```

Note the current version for comparison.

### 2. Review Changelog

Fetch the RTK changelog/releases for the target version:

```bash
gh release view <version> --repo rtk-ai/rtk
```

Or check https://github.com/rtk-ai/rtk/releases for the target version.

Flag any of these changes:
- New network calls or telemetry
- Changes to the hook rewrite logic
- New file system access patterns
- New dependencies
- Changes to the `rtk rewrite` exit code protocol

### 3. Run Audit Baseline

Run the audit task to capture current behavior before upgrading:

```bash
mise run rtk:audit --save-baseline
```

### 4. Upgrade RTK

Update the version in the Brewfile and install:

```bash
brew upgrade rtk
```

### 5. Run Post-Upgrade Audit

```bash
mise run rtk:audit
```

Review the diff output. Look for:
- Commands that were previously passed through but are now compressed
- Commands where compression is significantly more aggressive
- Any commands that produce empty or misleading output
- Changes in compression ratios (>10% change warrants investigation)

### 6. Security Check

Verify no new concerning behavior:

```bash
# Check for network calls
rtk --help | grep -i telemetry
# Check config for new options
rtk config show 2>/dev/null || true
```

### 7. Decision

If everything looks good:
1. Update the Brewfile version pin
2. Save the new baseline: `mise run rtk:audit --save-baseline`
3. Commit the changes

If concerning changes found:
1. Roll back: `brew install rtk@<previous-version>` or reinstall from Brewfile
2. File an issue or wait for a fix
3. Document concerns in the commit message if proceeding anyway
