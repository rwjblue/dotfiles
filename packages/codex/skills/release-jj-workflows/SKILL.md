---
name: release-jj-workflows
description: Build the JJ Workflows plugin from the dotfiles checkout and update its existing private Codex release. Use only when asked to build or release JJ Workflows.
---

# Release JJ Workflows

Use the dotfiles checkout selected by the user as the source. Its shared
skills and plugin manifest are the files to maintain.

## Build

Run `mise run codex:bundle-jj-workflows <version>` from the dotfiles root. It
prints the absolute path to a temporary ZIP containing six shared skills
and both manifests. Use the requested version for a build-only request and
return the archive path.

## Update the private plugin

1. Resolve the existing JJ Workflows plugin using Plugin Creator. Use the
   exact backend ID from a verified link, prior tool result, or the personal
   plugin listing. Confirm the package name is `jj-workflows` and its release
   is private. Use `get_plugin_files` to read the current manifests, skill
   inventory, and release ID. If the upload tools are unavailable, ask the
   user to attach Plugin Creator before uploading.
2. Use the requested higher version or increment the live patch version.
   Build the ZIP with the mise task. Inspect its JSON, skill frontmatter,
   file references, and file inventory. Compare with the live package.
   Preserve service-managed author metadata, account scope, and audience.
   If the only differences are the version and service-added author email,
   report that the current release already matches. Reconcile any unexpected
   live edits in the dotfiles source before replacing them.
3. When the user requests release, call `update_plugin` with the existing
   plugin ID, archive path, and observed `expected_release_id`. If the
   release changed, re-read it and rebuild from reconciled source. Preserve
   any files outside this bundle unless the user asks to remove them.
4. Re-read the release with `get_plugin_files`. Verify the version, both
   manifests, and packaged skills. Return the plugin link and report
   whether the new version reached the local Codex cache.
