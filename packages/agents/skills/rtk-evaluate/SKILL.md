---
name: rtk-evaluate
description: Evaluate an RTK version upgrade for safety and compatibility before updating the mise pin.
---

# RTK version evaluation

From the dotfiles checkout, check the installed version against the `github:rtk-ai/rtk` pin in `packages/mise/config.toml`. Review the candidate's [release notes](https://github.com/rtk-ai/rtk/releases) for changes to network activity, telemetry, filesystem access, dependencies, or the `rtk rewrite` command and its exit codes.

Capture the current pin's output before evaluating the candidate:

```bash
mise run rtk:audit --save-baseline
```

Set `candidate_version` to the release you reviewed, without the leading `v`. Use mise to select the candidate OSS executable for the audit:

```bash
candidate_binary=$(mise exec "github:rtk-ai/rtk[matching_regex=^rtk-oss-.*[.](tar[.]gz|zip)\$]@$candidate_version" -- which rtk)
"$candidate_binary" --version
mise run rtk:audit --rtk "$candidate_binary"
```

Verify that the reported version matches the candidate. Review the output diff for lost details, misleading summaries, and changes in compression or passthrough behavior. Inspect new configuration options with `"$candidate_binary" config`.

When accepting the candidate, change the version in `packages/mise/config.toml` and keep its OSS asset selector. Refresh the global lockfile, install from it, and record the new baseline:

```bash
mise lock --global github:rtk-ai/rtk
mise install --locked github:rtk-ai/rtk
mise run rtk:audit --save-baseline
```

Keep the config, lockfile, and baseline together when committing an upgrade. To roll back an applied upgrade, restore its previous version and lock entry, then run `mise install --locked github:rtk-ai/rtk`.
