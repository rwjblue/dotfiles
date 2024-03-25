pub fn in_tmux() -> bool {
    std::env::var("TMUX").is_ok()
}
