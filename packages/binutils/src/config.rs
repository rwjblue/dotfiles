use std::env;
use std::fmt;
use std::path::{Path, PathBuf};

use anyhow::Result;
use serde::de::{self, Visitor};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Session {
    pub name: String,
    pub windows: Vec<Window>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Window {
    pub name: String,
    #[serde(serialize_with = "path_to_string", deserialize_with = "string_to_path")]
    pub path: PathBuf,
    pub command: String,
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
