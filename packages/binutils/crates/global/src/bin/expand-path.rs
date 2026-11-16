use anyhow::{Context, Result};
use clap::Parser;
use std::env;
use std::io::{self, Write};

/// Print the entries in $PATH, one per line.
#[derive(Parser)]
#[clap(author, version, about)]
struct Cli {}

fn main() -> Result<()> {
    let _cli = Cli::parse();

    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("off")),
        )
        .init();

    latest_bin::ensure_latest_bin()?;

    let path = env::var_os("PATH").context("Failed reading $PATH")?;
    let mut stdout = io::stdout().lock();
    for part in env::split_paths(&path) {
        stdout.write_all(part.as_os_str().as_encoded_bytes())?;
        stdout.write_all(b"\n")?;
    }

    Ok(())
}
