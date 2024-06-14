use std::env;
use std::fmt;
use std::fs;
use std::fs::File;
use std::io::Write;
use std::path::{Path, PathBuf};

use anyhow::Result;
use serde::de::{self, Visitor};
use serde::{Deserialize, Serialize};
use toml;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
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
    pub path: PathBuf,
    pub command: Command,
}

pub fn get_config_file_path() -> PathBuf {
    let home_dir = env::var("HOME").expect("HOME environment variable not set");
    Path::new(&home_dir).join(".config/binutils/config.toml")
}

pub fn write_config(config: &Config) -> Result<()> {
    let config_path = get_config_file_path();
    let toml_str = toml::to_string_pretty(&config)?;

    let config_dir = config_path.parent().unwrap();
    fs::create_dir_all(config_dir)?;

    let mut file = File::create(config_path)?;
    file.write_all(toml_str.as_bytes())?;
    Ok(())
}

pub fn read_config() -> Result<Config> {
    let config_path = get_config_file_path();
    let toml_str = fs::read_to_string(config_path)?;
    let config: Config = toml::from_str(&toml_str)?;

    Ok(config)
}

fn path_to_string<S>(path: &Path, serializer: S) -> Result<S::Ok, S::Error>
where
    S: serde::Serializer,
{
    let path_with_tokens = revert_tokens_in_path(path);
    serializer.serialize_str(&path_with_tokens)
}

fn string_to_path<'de, D>(deserializer: D) -> Result<PathBuf, D::Error>
where
    D: serde::Deserializer<'de>,
{
    struct StringVisitor;

    impl<'de> Visitor<'de> for StringVisitor {
        type Value = PathBuf;

        fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
            formatter.write_str("a string representing a path")
        }

        fn visit_str<E>(self, v: &str) -> Result<Self::Value, E>
        where
            E: de::Error,
        {
            Ok(PathBuf::from(replace_tokens_in_path(v)))
        }
    }

    deserializer.deserialize_string(StringVisitor)
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
    use insta::{assert_snapshot, assert_toml_snapshot};
    use std::env;
    use tempfile::tempdir;

    #[derive(Debug, Clone)]
    struct TestEnvironment {
        _home: PathBuf,
        _config_dir: PathBuf,
        config_file: PathBuf,
        original_home: Option<String>,
    }

    impl Drop for TestEnvironment {
        fn drop(&mut self) {
            match &self.original_home {
                Some(home) => env::set_var("HOME", home),
                None => env::remove_var("HOME"),
            }
        }
    }

    fn setup_test_environment() -> TestEnvironment {
        let original_home = env::var("HOME").ok();
        let temp_dir = tempdir().expect("Failed to create temp dir");
        let temp_home = temp_dir.into_path();

        env::set_var(
            "HOME",
            temp_home
                .to_str()
                .expect("Failed to convert temp path to str"),
        );

        // Ensure config directory exists
        let config_dir = temp_home.join(".config/binutils");
        fs::create_dir_all(&config_dir).expect("Failed to create .config directory");

        TestEnvironment {
            _home: temp_home,
            config_file: config_dir.join("config.toml"),
            _config_dir: config_dir,
            original_home,
        }
    }

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
    fn test_write_and_read_config() {
        let env = setup_test_environment();

        let config = Config {
            tmux: Tmux {
                sessions: vec![Session {
                    name: "Test Session".to_string(),
                    windows: vec![Window {
                        name: "Test Window".to_string(),
                        path: PathBuf::from("/some/path"),
                        command: Command::Single("echo 'Hello, world!'".to_string()),
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
        let read_config = read_config().expect("Failed to read config");

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
                                path: PathBuf::from("/some/path"),
                                command: Command::Single("echo 'Hello, world!'".to_string()),
                            },
                            Window {
                                name: "Second Window".to_string(),
                                path: PathBuf::from("/some/other-path"),
                                command: Command::Single("nvim".to_string()),
                            },
                        ],
                    },
                    Session {
                        name: "Second Session".to_string(),
                        windows: vec![Window {
                            name: "Third Window".to_string(),
                            path: PathBuf::from("~/"),
                            command: Command::Multiple(vec![
                                "echo 'Hello, world!'".to_string(),
                                "echo 'Goodbye, world!'".to_string(),
                            ]),
                        }],
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

        [[tmux.sessions]]
        name = "Second Session"

        [[tmux.sessions.windows]]
        name = "Third Window"
        path = "~/"
        command = [
            "echo 'Hello, world!'",
            "echo 'Goodbye, world!'",
        ]
        '''
        "###);
    }
}
