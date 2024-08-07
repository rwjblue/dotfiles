use anyhow::{Context, Result};
use std::env;
use std::fs;
use std::path::Path;
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};
use tracing::{debug, info, trace};
use walkdir::{DirEntry, WalkDir};

fn modified_time(path: &Path) -> Result<SystemTime> {
    let metadata = fs::metadata(path).context(format!(
        "Failed to get metadata: {}",
        path.to_string_lossy()
    ))?;

    metadata.modified().context(format!(
        "Failed to get modified time for path: {}",
        path.to_string_lossy()
    ))
}

// TODO: we could use `ignore` crate to read .gitignore files
fn should_include(entry: &DirEntry) -> bool {
    if entry.file_type().is_dir() {
        let name = entry.file_name().to_str().unwrap_or("");
        name != "target" && name != ".git"
    } else {
        true
    }
}

// TODO: we could take the modified time of the env::current_exe() and just stop walking the first
// time we find a file that is newer
pub fn get_max_mod_time<P: AsRef<Path>>(dir: P) -> Result<SystemTime> {
    let mut max_mod_time = UNIX_EPOCH;

    for entry in WalkDir::new(dir).into_iter().filter_entry(should_include) {
        let entry = entry?;
        trace!("evaluating entry: {:?}", entry.path());
        if entry.file_type().is_file() {
            let mod_time = modified_time(entry.path())?;
            if mod_time > max_mod_time {
                debug!("Found newer file: {:?}", entry.path());
                max_mod_time = mod_time;
            }
        }
    }

    Ok(max_mod_time)
}

pub fn is_build_up_to_date() -> Result<bool> {
    let crate_root = env!("CARGO_MANIFEST_DIR");
    let current_exe = env::current_exe()?;

    debug!("crate_root: {}", crate_root);
    debug!("current_exe: {}", current_exe.to_string_lossy());

    let max_source_mod_time = get_max_mod_time(crate_root)?;
    let exe_mod_time = modified_time(&current_exe)?;

    let build_up_to_date = exe_mod_time >= max_source_mod_time;

    info!("build up to date: {}", build_up_to_date);

    Ok(build_up_to_date)
}

pub fn run_cargo_build() -> Result<()> {
    let crate_root = env!("CARGO_MANIFEST_DIR");
    info!("Running cargo build, in {}", crate_root);

    let path = Path::new(crate_root);
    if !path.exists() {
        anyhow::bail!("The specified path does not exist: {}", path.display());
    }

    let output = Command::new("cargo")
        .arg("build")
        .current_dir(path)
        .output()
        .context("Failed to execute cargo build command")?;

    if output.status.success() {
        Ok(())
    } else {
        println!("Cargo build failed.");
        println!("stdout: {}", String::from_utf8_lossy(&output.stdout));
        println!("stderr: {}", String::from_utf8_lossy(&output.stderr));
        anyhow::bail!("Cargo build failed with status: {}", output.status);
    }
}
