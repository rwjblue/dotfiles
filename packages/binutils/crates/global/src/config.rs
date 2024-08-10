use std::env;
use std::fs;
use std::fs::File;
use std::io::Write;
use std::path::{Path, PathBuf};
use tracing::{debug, error, info, trace};

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use toml;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    // TODO: make tmux optional
    pub tmux: Tmux,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Tmux {
    pub sessions: Vec<Session>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Session {
    pub name: String,
    pub windows: Vec<Window>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(untagged)]
pub enum Command {
    Single(String),
    Multiple(Vec<String>),
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Window {
    pub name: String,
    #[serde(serialize_with = "path_to_string", deserialize_with = "string_to_path")]
    pub path: Option<PathBuf>,
    pub command: Option<Command>,
}

fn default_config() -> Config {
    Config {
        // TODO: make tmux optional
        tmux: Tmux { sessions: vec![] },
    }
}

pub fn get_config_file_path() -> PathBuf {
    let home_dir = env::var("HOME").expect("HOME environment variable not set");
    Path::new(&home_dir).join(".config/binutils/config.toml")
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
        let config: Config = toml::from_str(&toml_str)
            // TODO: include the error information (e.g. why didn't it parse) into the context
            .with_context(|| format!("Could not parse config file: {}", &config_path.display()))?;
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

pub fn path_to_string<S>(path: &Option<PathBuf>, serializer: S) -> Result<S::Ok, S::Error>
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
    Ok(opt.map(|s| PathBuf::from(replace_tokens_in_path(&s))))
}

fn replace_tokens_in_path(path: &str) -> String {
    let home_dir = env::var("HOME").unwrap_or_default();
    path.replace("{home}", &home_dir)
}

fn revert_tokens_in_path(path: &Path) -> String {
    let home_dir = env::var("HOME").unwrap_or_default();
    let path_str = path.to_str().unwrap_or("");

    if path_str.starts_with(&home_dir) {
        path_str.replace(&home_dir, "{home}")
    } else {
        path_str.to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_utils::setup_test_environment;
    use insta::{assert_debug_snapshot, assert_snapshot, assert_toml_snapshot};
    use std::env;
    use tempfile::tempdir;

    #[test]
    fn test_replace_tokens_in_path_with_home() {
        let home_dir = env::var("HOME").expect("HOME not set");
        let path = "{home}/some/path";
        assert_eq!(
            replace_tokens_in_path(path),
            format!("{}/some/path", home_dir)
        );
    }

    #[test]
    fn test_revert_tokens_in_path_to_home() {
        let home_dir = env::var("HOME").expect("HOME not set");
        let path = PathBuf::from(format!("{}/some/path", home_dir));
        assert_eq!(revert_tokens_in_path(&path), "{home}/some/path");
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
        assert_eq!(replace_tokens_in_path("{home}"), home_dir);
    }

    #[test]
    fn test_path_just_home_directory() {
        let home_dir = env::var("HOME").expect("HOME not set");
        let path = PathBuf::from(&home_dir);
        assert_eq!(revert_tokens_in_path(&path), "{home}");
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
            tmux: Tmux {
                sessions: [],
            },
        }
        "###);
    }

    #[test]
    fn test_read_config_invalid_toml_contents() -> Result<()> {
        let env = setup_test_environment();

        let mut file = File::create(&env.config_file)?;
        file.write_all(b"invalid toml contents")?;

        let err = read_config(None).unwrap_err();

        assert_eq!(
            err.to_string(),
            format!(
                "Could not parse config file: {}",
                &env.config_file.display()
            )
        );

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
    fn test_write_and_read_config() {
        let env = setup_test_environment();

        let config = Config {
            tmux: Tmux {
                sessions: vec![Session {
                    name: "Test Session".to_string(),
                    windows: vec![Window {
                        name: "Test Window".to_string(),
                        path: Some(PathBuf::from("/some/path")),
                        command: Some(Command::Single("echo 'Hello, world!'".to_string())),
                    }],
                }],
            },
        };

        // Write the config
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

        assert_eq!(config.tmux.sessions, read_config.tmux.sessions);
    }

    #[test]
    fn test_write_config() {
        let env = setup_test_environment();

        let config = Config {
            tmux: Tmux {
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
                                path: Some(PathBuf::from("~/")),
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
            },
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
        path = "~/"
        command = [
            "echo 'Hello, world!'",
            "echo 'Goodbye, world!'",
        ]

        [[tmux.sessions.windows]]
        name = "Window without command"
        path = "/some/other-path"
        '''
        "###);
    }
}
