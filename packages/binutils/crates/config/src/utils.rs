use std::env;
use std::fs;
use std::fs::File;
use std::io::Write;
use std::path::{Path, PathBuf};
use tracing::{debug, error, trace};

use anyhow::{Context, Result};

use super::default_config;
use super::types::Config;

pub fn get_config_file_path() -> PathBuf {
    let home_dir = env::var("HOME").expect("HOME environment variable not set");
    Path::new(&home_dir).join(".config/binutils/config.toml")
}

fn expand_tilde(path: PathBuf) -> PathBuf {
    let path_str = path.to_str().unwrap_or_default();

    match path_str.strip_prefix('~') {
        Some(stripped) => {
            let home_dir = env::var("HOME").expect("HOME environment variable not set");
            let expanded = format!("{}{}", home_dir, stripped);

            PathBuf::from(expanded)
        }
        None => path,
    }
}

// TODO: support passing in a custom config path
pub fn write_config(config: &Config) -> Result<()> {
    let config_path = get_config_file_path();
    let toml_str = toml::to_string_pretty(&config)?;

    debug!("Writing config to: {}", config_path.display());
    trace!("Config: {}", toml_str);

    let config_dir = config_path.parent().unwrap();
    fs::create_dir_all(config_dir)?;

    let mut file = File::create(config_path)?;
    file.write_all(toml_str.as_bytes())?;
    Ok(())
}

pub fn read_config(config_path: Option<PathBuf>) -> Result<Config> {
    let config_path = match config_path {
        Some(config_path) => {
            let config_path = expand_tilde(config_path);

            if !config_path.is_file() {
                error!(
                    "The specified config path is not a file: {}",
                    config_path.display()
                );

                return Err(anyhow::anyhow!(
                    "The specified config path is not a file: {}",
                    config_path.display()
                ));
            }

            config_path
        }
        None => {
            trace!("No config path specified, using default config path");
            get_config_file_path()
        }
    };

    let config = if config_path.is_file() {
        debug!("Reading config from: {}", config_path.display());

        let toml_str = fs::read_to_string(&config_path).with_context(|| {
            format!(
                "Could not read config file from: {}",
                &config_path.display()
            )
        })?;
        let config: Config = toml::from_str(&toml_str).map_err(|e| {
            anyhow::anyhow!(
                "Could not parse config file: {}.\n\nParsing error:\n{}",
                &config_path.display(),
                e
            )
        })?;
        config
    } else {
        debug!(
            "Using default config. No config file found at: {}",
            config_path.display()
        );

        default_config()
    };

    trace!("Config: {:?}", config);

    Ok(config)
}

#[cfg(test)]
mod tests {
    use super::super::types::{Command, Config, Session, Tmux, Window};
    use super::*;
    use insta::{assert_debug_snapshot, assert_snapshot, assert_toml_snapshot};
    use std::env;
    use test_utils::{setup_test_environment, stabilize_home_paths};

    #[test]
    fn test_read_config_missing_file() {
        let _env = setup_test_environment();

        let config = read_config(None).expect("read_config(None) when no config exists failed");

        assert_debug_snapshot!(config, @r###"
        Config {
            tmux: Some(
                Tmux {
                    sessions: [],
                },
            ),
        }
        "###);
    }

    #[test]
    fn test_read_config_custom_file() {
        let env = setup_test_environment();

        let config_file_path = env.config_dir.join("custom-config.toml");
        let config = default_config();

        let mut file = File::create(&config_file_path).expect("Could not create file");
        let toml_str = toml::to_string_pretty(&config).expect("could not convert to toml");
        file.write_all(toml_str.as_bytes())
            .expect("could not write to config");

        let config = read_config(Some(config_file_path)).expect("error reading from config");

        assert_debug_snapshot!(config, @r###"
        Config {
            tmux: Some(
                Tmux {
                    sessions: [],
                },
            ),
        }
        "###);
    }

    #[test]
    fn test_read_config_custom_file_with_tilde() {
        let env = setup_test_environment();

        let config_file_path = env.home.join("custom-config.toml");
        let config = default_config();

        let mut file = File::create(config_file_path).expect("Could not create file");
        let toml_str = toml::to_string_pretty(&config).expect("could not convert to toml");
        file.write_all(toml_str.as_bytes())
            .expect("could not write to config");

        let config = read_config(Some(PathBuf::from("~/custom-config.toml")))
            .expect("could not read config");

        assert_debug_snapshot!(config, @r###"
        Config {
            tmux: Some(
                Tmux {
                    sessions: [],
                },
            ),
        }
        "###);
    }

    #[test]
    fn test_read_config_invalid_toml_contents() -> Result<()> {
        let env = setup_test_environment();

        let mut file = File::create(&env.config_file)?;
        file.write_all(b"invalid toml contents")?;

        let err = read_config(None).unwrap_err();

        assert_snapshot!(stabilize_home_paths(&env, &err.to_string()), @r###"
        Could not parse config file: ~/.config/binutils/config.toml.

        Parsing error:
        TOML parse error at line 1, column 9
          |
        1 | invalid toml contents
          |         ^
        expected `.`, `=`
        "###);

        Ok(())
    }

    #[test]
    fn test_read_config_missing_file_specified() {
        let _env = setup_test_environment();

        let result = read_config(Some(PathBuf::from("/some/nonexistent/file")));
        let err = result.unwrap_err();

        assert_snapshot!(err, @"The specified config path is not a file: /some/nonexistent/file");
    }

    #[test]
    fn test_write_and_read_config_tmux_windows_without_path() {
        let env = setup_test_environment();

        let config = Config {
            tmux: Some(Tmux {
                sessions: vec![Session {
                    name: "Test Session".to_string(),
                    windows: vec![Window {
                        name: "Test Window".to_string(),
                        path: None,
                        command: Some(Command::Single("echo 'Hello, world!'".to_string())),
                    }],
                }],
            }),
        };

        write_config(&config).expect("Failed to write config");

        let written_toml_str = fs::read_to_string(&env.config_file).expect("failed to read config");

        assert_toml_snapshot!(written_toml_str, @r###"
        '''
        [[tmux.sessions]]
        name = "Test Session"

        [[tmux.sessions.windows]]
        name = "Test Window"
        command = "echo 'Hello, world!'"
        '''
        "###);

        // Read the config
        let read_config = read_config(None).expect("Failed to read config");

        assert_eq!(config, read_config);
    }

    #[test]
    fn test_write_and_read_config() {
        let env = setup_test_environment();

        let config = Config {
            tmux: Some(Tmux {
                sessions: vec![Session {
                    name: "Test Session".to_string(),
                    windows: vec![Window {
                        name: "Test Window".to_string(),
                        path: Some(PathBuf::from("/some/path")),
                        command: Some(Command::Single("echo 'Hello, world!'".to_string())),
                    }],
                }],
            }),
        };

        write_config(&config).expect("Failed to write config");

        let written_toml_str = fs::read_to_string(&env.config_file).expect("failed to read config");

        assert_toml_snapshot!(written_toml_str, @r###"
        '''
        [[tmux.sessions]]
        name = "Test Session"

        [[tmux.sessions.windows]]
        name = "Test Window"
        path = "/some/path"
        command = "echo 'Hello, world!'"
        '''
        "###);

        // Read the config
        let read_config = read_config(None).expect("Failed to read config");

        assert_eq!(config.tmux, read_config.tmux);
    }

    #[test]
    fn test_write_config() {
        let env = setup_test_environment();

        let config = Config {
            tmux: Some(Tmux {
                sessions: vec![
                    Session {
                        name: "Test Session".to_string(),
                        windows: vec![
                            Window {
                                name: "Test Window".to_string(),
                                path: Some(PathBuf::from("/some/path")),
                                command: Some(Command::Single("echo 'Hello, world!'".to_string())),
                            },
                            Window {
                                name: "Second Window".to_string(),
                                path: Some(PathBuf::from("/some/other-path")),
                                command: Some(Command::Single("nvim".to_string())),
                            },
                            Window {
                                name: "Window without path".to_string(),
                                path: None,
                                command: Some(Command::Single("nvim".to_string())),
                            },
                        ],
                    },
                    Session {
                        name: "Second Session".to_string(),
                        windows: vec![
                            Window {
                                name: "Fourth Window".to_string(),
                                path: Some(env.home.clone()),
                                command: Some(Command::Multiple(vec![
                                    "echo 'Hello, world!'".to_string(),
                                    "echo 'Goodbye, world!'".to_string(),
                                ])),
                            },
                            Window {
                                name: "Window without command".to_string(),
                                path: Some(PathBuf::from("/some/other-path")),
                                command: None,
                            },
                        ],
                    },
                ],
            }),
        };

        // Write the config
        write_config(&config).expect("Failed to write config");

        // Assert that the config file was created
        let written_config = fs::read_to_string(&env.config_file).expect("Failed to read config");

        assert_toml_snapshot!(written_config, @r###"
        '''
        [[tmux.sessions]]
        name = "Test Session"

        [[tmux.sessions.windows]]
        name = "Test Window"
        path = "/some/path"
        command = "echo 'Hello, world!'"

        [[tmux.sessions.windows]]
        name = "Second Window"
        path = "/some/other-path"
        command = "nvim"

        [[tmux.sessions.windows]]
        name = "Window without path"
        command = "nvim"

        [[tmux.sessions]]
        name = "Second Session"

        [[tmux.sessions.windows]]
        name = "Fourth Window"
        path = "~"
        command = [
            "echo 'Hello, world!'",
            "echo 'Goodbye, world!'",
        ]

        [[tmux.sessions.windows]]
        name = "Window without command"
        path = "/some/other-path"
        '''
        "###);

        let final_config = read_config(None).expect("Failed to read config");

        assert_eq!(config, final_config);
    }
}
