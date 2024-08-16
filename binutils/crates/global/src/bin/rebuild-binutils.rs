use anyhow::Result;
use tracing_subscriber::EnvFilter;

fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .init();

    latest_bin::run_cargo_build()?;

    let crate_root = latest_bin::get_crate_root()?;
    binutils::build_utils::generate_symlinks(Some(crate_root))?;

    Ok(())
}
