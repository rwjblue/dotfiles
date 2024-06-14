use anyhow::Result;
use binutils::config::read_config;
use binutils::tmux;

fn main() -> Result<()> {
    let _config = read_config()?;

    Ok(())
}
