use anyhow::Result;
use binutils::latest_bin;
use tracing_subscriber::EnvFilter;

fn main() -> Result<()> {
    // Initialize tracing, but only if RUST_LOG is set
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("off")),
        )
        .init();

    latest_bin::ensure_latest_bin()?;

    Ok(())
}
