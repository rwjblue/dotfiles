use anyhow::{Context, Result};
use std::fs;
use std::path::PathBuf;

pub mod config {
    include!("src/config/types.rs");
}

fn main() -> Result<()> {
    let crate_root = PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").unwrap());
    let dest_path = crate_root.join("config_schema.json");

    let schema = schemars::schema_for!(config::Config);

    fs::write(
        &dest_path,
        serde_json::to_string_pretty(&schema).with_context(|| "error stringifying the schema")?,
    )
    .with_context(|| format!("error writing schema to {:?}", dest_path))?;

    Ok(())
}
