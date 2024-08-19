use std::collections::BTreeMap;
use std::env;
use std::fs;
use std::fs::File;
use std::io::Write;
use std::path::{Path, PathBuf};
use tracing::{debug, error, trace};

use anyhow::{Context, Result};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

/// Configuration for the application.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
pub struct Config {
    /// Optional tmux configuration. Including sessions and windows to be created.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tmux: Option<Tmux>,

    /// Optional configuration for cache-shell-setup
    #[serde(skip_serializing_if = "Option::is_none")]
    pub shell_caching: Option<ShellCache>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
pub struct ShellCache {
    pub source: String,
    pub destination: String,
}

/// Tmux configuration.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
pub struct Tmux {
    /// List of tmux sessions.
    pub sessions: Vec<Session>,

    /// The default session to attach to when `startup-tmux --attach` is ran.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub default_session: Option<String>,
}

/// Configuration for a tmux session.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
pub struct Session {
    /// Name of the session.
    pub name: String,
    /// List of windows in the session.
    pub windows: Vec<Window>,
}

/// Command to be executed in a tmux window.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
#[serde(untagged)]
pub enum Command {
    /// A single command as a string.
    Single(String),
    /// Multiple commands as a list of strings.
    Multiple(Vec<String>),
}

/// Configuration for a tmux window.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
pub struct Window {
    /// Name of the window.
    pub name: String,
    /// Optional path to set as the working directory for the window.
    #[serde(
        default,
        serialize_with = "path_to_string",
        deserialize_with = "string_to_path",
        skip_serializing_if = "Option::is_none"
    )]
    pub path: Option<PathBuf>,

    /// Optional command to run in the window.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub command: Option<Command>,

    /// Additional environment variables to set in the window.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub env: Option<BTreeMap<String, String>>,
}

pub fn default_config() -> Config {
    Config {
        shell_caching: None,
        tmux: Some(Tmux {
            default_session: None,
            sessions: vec![],
        }),
    }
}

fn path_to_string<S>(path: &Option<PathBuf>, serializer: S) -> Result<S::Ok, S::Error>
where
    S: serde::Serializer,
{
    match path {
        Some(p) => {
            let path_str = revert_tokens_in_path(p);
            serializer.serialize_some(&path_str)
        }
        None => serializer.serialize_none(),
    }
}

fn string_to_path<'de, D>(deserializer: D) -> Result<Option<PathBuf>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    let opt = Option::<String>::deserialize(deserializer)?;
    match opt {
        Some(s) => Ok(Some(PathBuf::from(replace_tokens_in_path(&s)))),
        None => Ok(None),
    }
}

fn replace_tokens_in_path(path: &str) -> String {
    match path.strip_prefix('~') {
        Some(stripped) => {
            let home_dir = env::var("HOME").expect("HOME environment variable not set");

            format!("{}{}", home_dir, stripped)
        }
        None => path.to_string(),
    }
}

fn revert_tokens_in_path(path: &Path) -> String {
    let home_dir = env::var("HOME").unwrap_or_default();
    let path_str = path.to_str().unwrap_or("");

    match path_str.strip_prefix(&home_dir) {
        Some(stripped) => {
            format!("~{}", stripped)
        }
        None => path_str.to_string(),
    }
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

pub fn write_config(config: &Config, config_path: Option<PathBuf>) -> Result<()> {
    let config_path = if let Some(config_path) = config_path {
        config_path
    } else {
        let home_dir = env::var("HOME").expect("HOME environment variable not set");
        Path::new(&home_dir).join(".config/binutils/config.yaml")
    };

    let yaml_str = serde_yml::to_string(&config)?;

    debug!("Writing config to: {}", config_path.display());
    trace!("Config: {}", yaml_str);

    let config_dir = config_path.parent().unwrap();
    fs::create_dir_all(config_dir)?;

    let mut file = File::create(config_path)?;
    file.write_all(yaml_str.as_bytes())?;
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

            let home_dir = env::var("HOME").expect("HOME environment variable not set");

            let local_config_file = Path::new(&home_dir).join(".config/binutils/local.config.yaml");
            if local_config_file.exists() {
                local_config_file
            } else {
                Path::new(&home_dir).join(".config/binutils/config.yaml")
            }
        }
    };

    let config = if config_path.is_file() {
        debug!("Reading config from: {}", config_path.display());

        let yaml_str = fs::read_to_string(&config_path).with_context(|| {
            format!(
                "Could not read config file from: {}",
                &config_path.display()
            )
        })?;
        let config: Config = serde_yml::from_str(&yaml_str).map_err(|e| {
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
    use super::*;
    use insta::{assert_debug_snapshot, assert_snapshot};
    use std::env;
    use tempfile::tempdir;
    use test_utils::{setup_test_environment, stabilize_home_paths};

    #[test]
    fn test_replace_tokens_in_path_with_home() {
        let home_dir = env::var("HOME").expect("HOME not set");
        let path = "~/some/path";
        assert_eq!(
            replace_tokens_in_path(path),
            format!("{}/some/path", home_dir)
        );
    }

    #[test]
    fn test_revert_tokens_in_path_to_home() {
        let home_dir = env::var("HOME").expect("HOME not set");
        let path = PathBuf::from(format!("{}/some/path", home_dir));
        assert_eq!(revert_tokens_in_path(&path), "~/some/path");
    }

    #[test]
    fn test_replace_tokens_in_path_without_home() {
        let path = "/some/other/path";
        assert_eq!(replace_tokens_in_path(path), "/some/other/path");
    }

    #[test]
    fn test_revert_tokens_in_path_without_home() {
        let path = PathBuf::from("/some/other/path");
        assert_eq!(revert_tokens_in_path(&path), "/some/other/path");
    }

    #[test]
    fn test_replace_empty_path() {
        assert_eq!(replace_tokens_in_path(""), "");
    }

    #[test]
    fn test_revert_empty_path() {
        let path = PathBuf::from("");
        assert_eq!(revert_tokens_in_path(&path), "");
    }

    #[test]
    fn test_path_just_home_token() {
        let home_dir = env::var("HOME").expect("HOME not set");
        assert_eq!(replace_tokens_in_path("~"), home_dir);
    }

    #[test]
    fn test_path_just_home_directory() {
        let home_dir = env::var("HOME").expect("HOME not set");
        let path = PathBuf::from(&home_dir);
        assert_eq!(revert_tokens_in_path(&path), "~");
    }

    // This test ensures that paths without the home directory are handled correctly
    #[test]
    fn test_temporary_directory_handling() {
        let temp_dir = tempdir().expect("Failed to create a temporary directory");
        let temp_path = temp_dir.path();
        let temp_path_str = temp_path
            .to_str()
            .expect("Failed to convert temp path to str");

        assert_eq!(
            replace_tokens_in_path(temp_path_str),
            temp_path_str,
            "Temporary paths should not be altered if they do not contain the home directory."
        );
    }

    #[test]
    fn test_read_config_missing_file() {
        let _env = setup_test_environment();

        let config = read_config(None).expect("read_config(None) when no config exists failed");

        assert_debug_snapshot!(config, @r###"
        Config {
            tmux: Some(
                Tmux {
                    sessions: [],
                    default_session: None,
                },
            ),
            shell_caching: None,
        }
        "###);
    }

    #[test]
    fn test_read_default_custom_config_file_path() {
        let env = setup_test_environment();

        let config_file_path = env.config_dir.join("custom-config.yaml");
        let config = default_config();

        let mut file = File::create(&config_file_path).expect("Could not create file");
        let yaml_str = serde_yml::to_string(&config).expect("could not convert to yaml");
        file.write_all(yaml_str.as_bytes())
            .expect("could not write to config");

        let config = read_config(Some(config_file_path)).expect("error reading from config");

        assert_debug_snapshot!(config, @r###"
        Config {
            tmux: Some(
                Tmux {
                    sessions: [],
                    default_session: None,
                },
            ),
            shell_caching: None,
        }
        "###);
    }

    #[test]
    fn test_read_default_local_config_file() {
        let env = setup_test_environment();

        let config_file_path = env.config_dir.join("local.config.yaml");
        let config = Config {
            shell_caching: None,
            tmux: Some(Tmux {
                default_session: Some("Test Session".to_string()),
                sessions: vec![Session {
                    name: "Test Session".to_string(),
                    windows: vec![Window {
                        name: "Test Window".to_string(),
                        path: None,
                        command: Some(Command::Single("echo 'Hello, world!'".to_string())),
                        env: None,
                    }],
                }],
            }),
        };

        let mut file = File::create(&config_file_path).expect("Could not create file");
        let yaml_str = serde_yml::to_string(&config).expect("could not convert to yaml");
        file.write_all(yaml_str.as_bytes())
            .expect("could not write to config");

        let config = read_config(None).expect("error reading from config");

        assert_debug_snapshot!(config, @r###"
        Config {
            tmux: Some(
                Tmux {
                    sessions: [
                        Session {
                            name: "Test Session",
                            windows: [
                                Window {
                                    name: "Test Window",
                                    path: None,
                                    command: Some(
                                        Single(
                                            "echo 'Hello, world!'",
                                        ),
                                    ),
                                    env: None,
                                },
                            ],
                        },
                    ],
                    default_session: Some(
                        "Test Session",
                    ),
                },
            ),
            shell_caching: None,
        }
        "###);
    }

    #[test]
    fn test_read_config_local_config_wins() {
        let env = setup_test_environment();

        let local_config_path = env.config_dir.join("local.config.yaml");
        let config = Config {
            shell_caching: None,
            tmux: None,
        };

        let mut file = File::create(&local_config_path).expect("Could not create file");
        let yaml_str = serde_yml::to_string(&config).expect("could not convert to yaml");
        file.write_all(yaml_str.as_bytes())
            .expect("could not write to config");

        let local_config_path = env.config_dir.join("config.yaml");
        let config = Config {
            shell_caching: Some(ShellCache {
                source: "~/foo".to_string(),
                destination: "~/foo/dist".to_string(),
            }),
            tmux: None,
        };

        let mut file = File::create(&local_config_path).expect("Could not create file");
        let yaml_str = serde_yml::to_string(&config).expect("could not convert to yaml");
        file.write_all(yaml_str.as_bytes())
            .expect("could not write to config");

        let config = read_config(None).expect("error reading from config");

        assert_debug_snapshot!(config, @r###"
        Config {
            tmux: None,
            shell_caching: None,
        }
        "###);
    }

    #[test]
    fn test_read_config_custom_file_with_tilde() {
        let env = setup_test_environment();

        let config_file_path = env.home.join("custom-config.yaml");
        let config = default_config();

        let mut file = File::create(config_file_path).expect("Could not create file");
        let yaml_str = serde_yml::to_string(&config).expect("could not convert to yaml");
        file.write_all(yaml_str.as_bytes())
            .expect("could not write to config");

        let config = read_config(Some(PathBuf::from("~/custom-config.yaml")))
            .expect("could not read config");

        assert_debug_snapshot!(config, @r###"
        Config {
            tmux: Some(
                Tmux {
                    sessions: [],
                    default_session: None,
                },
            ),
            shell_caching: None,
        }
        "###);
    }

    #[test]
    fn test_read_config_invalid_yaml() -> Result<()> {
        let env = setup_test_environment();

        let mut file = File::create(&env.config_file)?;
        file.write_all(b"invalid yaml contents")?;

        let err = read_config(None).unwrap_err();

        assert_snapshot!(stabilize_home_paths(&env, &err.to_string()), @r###"
        Could not parse config file: ~/.config/binutils/config.yaml.

        Parsing error:
        invalid type: string "invalid yaml contents", expected struct Config
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
            shell_caching: None,
            tmux: Some(Tmux {
                default_session: Some("Test Session".to_string()),
                sessions: vec![Session {
                    name: "Test Session".to_string(),
                    windows: vec![Window {
                        name: "Test Window".to_string(),
                        path: None,
                        command: Some(Command::Single("echo 'Hello, world!'".to_string())),
                        env: None,
                    }],
                }],
            }),
        };

        write_config(&config, None).expect("Failed to write config");

        let written_yaml_str = fs::read_to_string(&env.config_file).expect("failed to read config");

        assert_snapshot!(written_yaml_str, @r###"
        tmux:
          sessions:
          - name: Test Session
            windows:
            - name: Test Window
              command: echo 'Hello, world!'
          default_session: Test Session
        "###);

        // Read the config
        let read_config = read_config(None).expect("Failed to read config");

        assert_eq!(config, read_config);
    }

    #[test]
    fn test_write_and_read_config() {
        let env = setup_test_environment();

        let config = Config {
            shell_caching: None,
            tmux: Some(Tmux {
                default_session: Some("Test Session".to_string()),
                sessions: vec![Session {
                    name: "Test Session".to_string(),
                    windows: vec![Window {
                        name: "Test Window".to_string(),
                        path: Some(PathBuf::from("/some/path")),
                        command: Some(Command::Single("echo 'Hello, world!'".to_string())),
                        env: None,
                    }],
                }],
            }),
        };

        write_config(&config, None).expect("Failed to write config");

        let written_yaml_str = fs::read_to_string(&env.config_file).expect("failed to read config");

        assert_snapshot!(written_yaml_str, @r###"
        tmux:
          sessions:
          - name: Test Session
            windows:
            - name: Test Window
              path: /some/path
              command: echo 'Hello, world!'
          default_session: Test Session
        "###);

        // Read the config
        let read_config = read_config(None).expect("Failed to read config");

        assert_eq!(config.tmux, read_config.tmux);
    }

    #[test]
    fn test_write_config() {
        let env = setup_test_environment();

        let config = Config {
            shell_caching: None,
            tmux: Some(Tmux {
                default_session: Some("Test Session".to_string()),
                sessions: vec![
                    Session {
                        name: "Test Session".to_string(),
                        windows: vec![
                            Window {
                                name: "Test Window".to_string(),
                                path: Some(PathBuf::from("/some/path")),
                                command: Some(Command::Single("echo 'Hello, world!'".to_string())),
                                env: None,
                            },
                            Window {
                                name: "Second Window".to_string(),
                                path: Some(PathBuf::from("/some/other-path")),
                                command: Some(Command::Single("nvim".to_string())),
                                env: None,
                            },
                            Window {
                                name: "Window without path".to_string(),
                                path: None,
                                command: Some(Command::Single("nvim".to_string())),
                                env: None,
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
                                env: None,
                            },
                            Window {
                                name: "Window without command".to_string(),
                                path: Some(PathBuf::from("/some/other-path")),
                                command: None,
                                env: None,
                            },
                        ],
                    },
                ],
            }),
        };

        // Write the config
        write_config(&config, None).expect("Failed to write config");

        // Assert that the config file was created
        let written_config = fs::read_to_string(&env.config_file).expect("Failed to read config");

        assert_snapshot!(written_config, @r###"
        tmux:
          sessions:
          - name: Test Session
            windows:
            - name: Test Window
              path: /some/path
              command: echo 'Hello, world!'
            - name: Second Window
              path: /some/other-path
              command: nvim
            - name: Window without path
              command: nvim
          - name: Second Session
            windows:
            - name: Fourth Window
              path: '~'
              command:
              - echo 'Hello, world!'
              - echo 'Goodbye, world!'
            - name: Window without command
              path: /some/other-path
          default_session: Test Session
        "###);

        let final_config = read_config(None).expect("Failed to read config");

        assert_eq!(config, final_config);
    }
}
