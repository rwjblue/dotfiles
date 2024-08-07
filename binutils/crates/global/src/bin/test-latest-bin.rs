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

    if latest_bin::is_build_up_to_date()? {
        println!("Build is up to date");
    } else {
        latest_bin::run_cargo_build()?;

        println!("Build is up to date");
    }

    Ok(())
}
