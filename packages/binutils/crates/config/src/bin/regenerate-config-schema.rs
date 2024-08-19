use clap::Parser;
use std::fs;
use std::path::PathBuf;

use anyhow::{Context, Result};
use tracing_subscriber::EnvFilter;

#[derive(Parser, Debug)]
#[command(
    name = "Regenerate Config Schema",
    about = "Regenerates the config schema"
)]
struct Args {
    /// Sets the output file path. Defaults to `config_schema.json` in the crate root.
    #[arg(short, long, value_name = "FILE")]
    output: Option<String>,
}

fn run(args: Vec<String>) -> Result<()> {
    let args = Args::parse_from(args);

    let dest_path = if let Some(output) = args.output {
        PathBuf::from(output)
    } else {
        let crate_root = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        crate_root.join("config_schema.json")
    };

    let schema = schemars::schema_for!(config::Config);

    let new_content =
        serde_json::to_string_pretty(&schema).with_context(|| "error stringifying the schema")?;
    let existing_content = fs::read_to_string(&dest_path).unwrap_or_default();

    // Only write if the file is different (keep the output stable if possible)
    if existing_content != new_content {
        fs::write(&dest_path, new_content)
            .with_context(|| format!("error writing schema to {:?}", dest_path))?;
    }

    Ok(())
}

fn main() -> Result<()> {
    // Initialize tracing, use `info` by default
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .init();

    latest_bin::ensure_latest_bin()?;

    run(std::env::args().collect())
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    #[test]
    fn test_run_generates_config_file() {
        // Create a temporary directory
        let temp_dir = tempdir().expect("Failed to create temp dir");
        let config_file_path = temp_dir.path().join("config_schema.json");

        // Call the run function (assuming it takes the output directory as an argument)
        run(vec![
            "regenerate-config-schema".to_string(),
            "--output".to_string(),
            config_file_path.to_string_lossy().to_string(),
        ])
        .expect("Failed to run the function");

        // Check if the config file exists
        assert!(config_file_path.exists(), "Config file was not generated");

        // Optionally, verify the contents of the generated file
        // let contents = fs::read_to_string(config_file_path).expect("Failed to read config file");
        // assert_eq!(contents, expected_contents);

        // Clean up is handled by the tempdir when it goes out of scope
    }
}
