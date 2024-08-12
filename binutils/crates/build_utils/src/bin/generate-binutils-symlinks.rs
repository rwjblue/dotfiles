use anyhow::Result;
use tracing_subscriber::EnvFilter;

fn main() -> Result<()> {
    // Initialize tracing, use `info` by default
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .init();

    build_utils::generate_symlinks()?;

    Ok(())
}
