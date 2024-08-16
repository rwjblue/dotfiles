use anyhow::{Context, Result};
use std::fs;
use std::path::PathBuf;

pub mod config {
    include!("src/types.rs");
}

fn main() -> Result<()> {
    let crate_root = PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").unwrap());
    let dest_path = crate_root.join("config_schema.json");

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
