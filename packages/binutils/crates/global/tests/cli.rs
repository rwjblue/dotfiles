use std::ffi::OsString;
use std::fs;
use std::os::unix::ffi::OsStringExt;
use std::process::{Command, Output};

use anyhow::{Result, ensure};
use tempfile::tempdir;

fn successful_stdout(output: Output) -> Result<Vec<u8>> {
    ensure!(
        output.status.success(),
        "{}",
        String::from_utf8_lossy(&output.stderr)
    );
    Ok(output.stdout)
}

#[test]
fn expand_path_preserves_raw_bytes_and_empty_entries() -> Result<()> {
    let path = OsString::from_vec(b":/first:/non-utf8-\xff:".to_vec());
    let output = Command::new(env!("CARGO_BIN_EXE_expand-path"))
        .env("SKIP_LATEST_BIN_CHECK", "1")
        .env("PATH", path)
        .output()?;
    assert_eq!(successful_stdout(output)?, b"\n/first\n/non-utf8-\xff\n\n");
    Ok(())
}

#[test]
fn expand_path_help_works_outside_the_workspace() -> Result<()> {
    let dir = tempdir()?;
    let bin = dir.path().join("expand-path");
    fs::copy(env!("CARGO_BIN_EXE_expand-path"), &bin)?;
    let output = Command::new(bin)
        .env_remove("SKIP_LATEST_BIN_CHECK")
        .env_remove("PATH")
        .arg("--help")
        .output()?;
    let help = String::from_utf8(successful_stdout(output)?)?;
    assert!(help.contains("Usage: expand-path"));
    Ok(())
}

#[test]
fn debug_path_reports_string_and_zsh_array_assignments() -> Result<()> {
    let home = tempdir()?;
    let zshrc = home.path().join(".zshrc");
    fs::write(
        &zshrc,
        concat!(
            "export PATH=\"/first:$PATH\"\n",
            "path=(/second $path)\n",
            "path+=(/third)\n",
            "OTHER=/ignored\n",
        ),
    )?;
    let output = Command::new(env!("CARGO_BIN_EXE_debug-path"))
        .env("HOME", home.path())
        .output()?;
    let output = String::from_utf8(successful_stdout(output)?)?;
    let prefix = format!("{}:", zshrc.display());
    let assignments: Vec<_> = output
        .lines()
        .filter_map(|line| line.strip_prefix(&prefix))
        .collect();
    assert_eq!(
        assignments,
        [
            "1: export PATH=\"/first:$PATH\"",
            "2: path=(/second $path)",
            "3: path+=(/third)",
        ]
    );
    Ok(())
}
