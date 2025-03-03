# zsh completions

This folder should only be used to add completions for things that are **not**
installed via Homebrew. The Homebrew package completions are already handled
automatically as part of the Homebrew installation process (along with a custom
`fpath` that is added by prezto/completions module).

Right now, this means `rustup`, `cargo`, and `go-task` completions only
(because those are all installed outside of Homebrew)..
