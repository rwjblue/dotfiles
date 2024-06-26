use std::env;
use std::fs;
use std::path::PathBuf;

use tempfile::tempdir;

#[derive(Debug, Clone)]
pub struct TestEnvironment {
    _home: PathBuf,
    _config_dir: PathBuf,
    pub config_file: PathBuf,
    pub original_home: Option<String>,
}

impl Drop for TestEnvironment {
    fn drop(&mut self) {
        match &self.original_home {
            Some(home) => env::set_var("HOME", home),
            None => env::remove_var("HOME"),
        }
    }
}

pub fn setup_test_environment() -> TestEnvironment {
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
