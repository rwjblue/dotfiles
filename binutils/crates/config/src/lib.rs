mod types;
mod utils;

pub use types::{default_config, Command, Config, Session, Tmux, Window};
pub use utils::{read_config, write_config};

// TODO: look into changing config to YAML
// TODO: add support for either "local.config.toml" over `config.toml` if present, or adding some
// sort of #include like system to the config file
