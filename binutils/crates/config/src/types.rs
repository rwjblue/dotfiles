use std::env;
use std::path::{Path, PathBuf};

use anyhow::Result;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

/// Configuration for the application.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
pub struct Config {
    /// Optional tmux configuration. Including sessions and windows to be created.
    pub tmux: Option<Tmux>,
}

/// Tmux configuration.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
pub struct Tmux {
    /// List of tmux sessions.
    pub sessions: Vec<Session>,
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
        deserialize_with = "string_to_path"
    )]
    pub path: Option<PathBuf>,
    /// Optional command to run in the window.
    pub command: Option<Command>,
}

pub fn default_config() -> Config {
    Config {
        tmux: Some(Tmux { sessions: vec![] }),
    }
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
    match opt {
        Some(s) => Ok(Some(PathBuf::from(replace_tokens_in_path(&s)))),
        None => Ok(None),
    }
}

pub fn replace_tokens_in_path(path: &str) -> String {
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

#[cfg(test)]
mod tests {
    use super::*;

    use std::env;
    use tempfile::tempdir;

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
}
