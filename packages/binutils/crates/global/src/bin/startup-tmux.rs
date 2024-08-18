use std::path::PathBuf;

use anyhow::Result;
use binutils::tmux::{startup_tmux, TmuxOptions};
use clap::Parser;
use config::read_config;
use tracing_subscriber::EnvFilter;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct CliTmuxOptions {
    /// Enable dry run mode. No commands will be executed.
    #[arg(long)]
    dry_run: bool,

    /// Enable debug mode. Provides additional output for debugging.
    #[arg(long)]
    debug: bool,

    /// Attach to the tmux session after starting it. Defaults to attaching if not within a
    /// TMUX session already.
    #[arg(long)]
    attach: Option<bool>,

    /// Specify the tmux socket name. Defaults to the main tmux socket.
    #[arg(long)]
    socket_name: Option<String>,

    /// Path to the configuration file. Defaults to `~/.config/binutils/config.yaml`.
    #[arg(long)]
    config_file: Option<String>,
}

impl TmuxOptions for CliTmuxOptions {
    fn is_dry_run(&self) -> bool {
        self.dry_run
    }

    fn is_debug(&self) -> bool {
        self.debug
    }

    fn should_attach(&self) -> Option<bool> {
        self.attach
    }

    fn socket_name(&self) -> Option<String> {
        self.socket_name.clone()
    }

    fn config_file(&self) -> Option<PathBuf> {
        self.config_file.as_ref().map(PathBuf::from)
    }
}

fn main() -> Result<()> {
    // Initialize tracing, but only if RUST_LOG is set
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("off")),
        )
        .init();

    latest_bin::ensure_latest_bin()?;

    let options = CliTmuxOptions::parse();
    let config = read_config(options.config_file())?;

    let commands = startup_tmux(&config, &options)?;

    if options.dry_run {
        println!("Would run the following commands:");
        for command in commands {
            println!("\t{}", command);
        }
    }

    Ok(())
}
