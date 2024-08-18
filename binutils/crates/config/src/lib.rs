mod types;
mod utils;

pub use types::{default_config, Command, Config, Session, Tmux, Window};
pub use utils::{read_config, write_config};

// TODO: add support for either "local.config.toml" over `config.toml` if present, or adding some
// sort of #include like system to the config file
// TODO: add support for specifying the default session to connect to when `startup-tmux --attach`
// is ran
// TODO: add support within a tmux window to specify environment variables (can be set with `tmux
// new-window -e FOO=bar`)
