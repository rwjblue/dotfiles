use anyhow::{Context, Result};
use clap::Parser;
use std::env;

/// A tool to debug and inspect the $PATH environment variable.
#[derive(Parser)]
#[clap(author, version, about)]
struct Cli {}

fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("off")),
        )
        .init();

    latest_bin::ensure_latest_bin()?;

    let _cli = Cli::parse();

    let path = env::var("PATH").context("Failed reading $PATH")?;
    for part in path.split(':') {
        println!("{}", part);
    }

    Ok(())
}
