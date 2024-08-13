use std::path::PathBuf;

use anyhow::Result;
use tracing_subscriber::EnvFilter;

fn main() -> Result<()> {
    // Initialize tracing, use `info` by default
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .init();

    latest_bin::ensure_latest_bin()?;

    let crate_root = env!("CARGO_MANIFEST_DIR");
    build_utils::generate_symlinks(Some(PathBuf::from(crate_root)))?;

    Ok(())
}
