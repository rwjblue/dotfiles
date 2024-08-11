use std::env;
use std::path::{Path, PathBuf};

use anyhow::Result;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Config {
    pub tmux: Option<Tmux>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
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
    #[serde(
        default,
        serialize_with = "path_to_string",
        deserialize_with = "string_to_path"
    )]
    pub path: Option<PathBuf>,
    pub command: Option<Command>,
}

pub fn default_config() -> Config {
    Config {
        // TODO: make tmux optional
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

// TODO: use ~ instead of {home} (duh)
fn replace_tokens_in_path(path: &str) -> String {
    let home_dir = env::var("HOME").unwrap_or_default();
    path.replace("{home}", &home_dir)
}

// TODO: use ~ instead of {home} (duh)
fn revert_tokens_in_path(path: &Path) -> String {
    let home_dir = env::var("HOME").unwrap_or_default();
    let path_str = path.to_str().unwrap_or("");

    if path_str.starts_with(&home_dir) {
        path_str.replace(&home_dir, "{home}")
    } else {
        path_str.to_string()
    }
}

// TODO: move this into replace_tokens_in_path and revert_tokens_in_path
pub fn expand_tilde(path: PathBuf) -> PathBuf {
    let path_str = path.to_str().unwrap_or_default();

    match path_str.strip_prefix("~") {
        Some(stripped) => {
            let home_dir = env::var("HOME").expect("HOME environment variable not set");
            let expanded = format!("{}{}", home_dir, stripped);

            PathBuf::from(expanded)
        }
        None => path,
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
}
