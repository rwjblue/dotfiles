pub fn in_tmux() -> bool {
    std::env::var("TMUX").is_ok()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_utils::setup_test_environment;

    #[test]
    fn test_in_tmux_within_tmux() {
        temp_env::with_var(
            "TMUX",
            Some("/private/tmp/tmux-23547/default,39774,0"),
            || {
                assert!(in_tmux());
            },
        );
    }

    #[test]
    fn test_in_tmux_outside_tmux() {
        temp_env::with_var("TMUX", None::<String>, || {
            assert!(!in_tmux());
        });
    }
}
