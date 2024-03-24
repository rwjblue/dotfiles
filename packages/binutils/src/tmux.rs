use std::path::{Path, PathBuf};

use anyhow::Result;
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

// Helper function to serialize a PathBuf
fn path_to_string<S>(path: &Path, serializer: S) -> Result<S::Ok, S::Error>
where
    S: serde::Serializer,
{
    serializer.serialize_str(path.to_str().unwrap_or(""))
}

// Helper function to deserialize a string to PathBuf
fn string_to_path<'de, D>(deserializer: D) -> Result<PathBuf, D::Error>
where
    D: serde::Deserializer<'de>,
{
    let s = String::deserialize(deserializer)?;
    Ok(PathBuf::from(s))
}

pub fn in_tmux() -> bool {
    std::env::var("TMUX").is_ok()
}
