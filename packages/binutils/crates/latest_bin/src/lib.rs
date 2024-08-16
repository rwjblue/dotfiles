use anyhow::{Context, Result};
use nix::unistd::execv;
use std::ffi::CString;
use std::fs;
use std::path::Path;
use std::process::Command;
use std::time::SystemTime;
use std::{env, path::PathBuf};
use tracing::{debug, info, trace};
use walkdir::{DirEntry, WalkDir};

fn modified_time(path: &Path) -> Result<SystemTime> {
    let metadata =
        fs::metadata(path).context(format!("Failed to get metadata: {}", path.display()))?;

    metadata.modified().context(format!(
        "Failed to get modified time for path: {}",
        path.display()
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

pub fn has_updated_files<P: AsRef<Path>>(dir: P, current_exe_mod_time: SystemTime) -> Result<bool> {
    for entry in WalkDir::new(dir).into_iter().filter_entry(should_include) {
        let entry = entry?;
        trace!("evaluating entry: {:?}", entry.path());
        if entry.file_type().is_file() {
            let mod_time = modified_time(entry.path())?;
            if mod_time > current_exe_mod_time {
                debug!("Found newer file: {:?}", entry.path());
                return Ok(true);
            }
        }
    }

    Ok(false)
}

/// Get the path to the current executable making sure it is canonicalized.
fn get_current_exe() -> Result<PathBuf> {
    let current_exe = env::current_exe().context("Failed to get the current executable path")?;
    let canonicalized_exe = current_exe
        .canonicalize()
        .context("Failed to canonicalize the executable path")?;
    Ok(canonicalized_exe)
}

/// Finds the nearest crate root by traversing up the directory tree from the current executable
/// (after resolving symlinks).
fn get_crate_root() -> Result<PathBuf> {
    let current_exe = get_current_exe()?;
    let mut path = current_exe.as_path();

    while let Some(parent) = path.parent() {
        if parent.join("Cargo.toml").exists() {
            return Ok(parent.to_path_buf());
        }
        path = parent;
    }

    Err(anyhow::anyhow!("Failed to find workspace root"))
}

pub fn needs_rebuild() -> Result<bool> {
    let crate_root = get_crate_root()?;
    let current_exe = get_current_exe()?;

    debug!("crate_root: {}", crate_root.display());
    debug!("current_exe: {}", current_exe.display());

    let exe_mod_time = modified_time(&current_exe)?;
    let needs_rebuild = has_updated_files(crate_root, exe_mod_time)?;

    info!("needs_rebuild: {}", needs_rebuild);

    Ok(needs_rebuild)
}

pub fn run_cargo_build() -> Result<()> {
    let crate_root = get_crate_root()?;
    info!("Running cargo build, in {}", crate_root.display());

    if !crate_root.exists() {
        anyhow::bail!(
            "The specified path does not exist: {}",
            crate_root.display()
        );
    }

    let output = Command::new("cargo")
        .arg("build")
        .current_dir(crate_root)
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

pub fn exec_updated_bin() -> Result<()> {
    let current_exe = get_current_exe()?;

    let exe_cstring = CString::new(
        current_exe
            .to_str()
            .context("Executable path is not valid UTF-8")?,
    )
    .context("Failed to convert executable path to CString")?;

    let args: Vec<CString> = env::args()
        .map(|arg| CString::new(arg).context("Failed to convert argument to CString"))
        .collect::<Result<Vec<CString>>>()?;

    let args_ref: Vec<&CString> = args.iter().collect();

    execv(&exe_cstring, &args_ref).context("Failed to execv the current executable")?;

    Ok(())
}

pub fn ensure_latest_bin() -> Result<()> {
    if !cfg!(debug_assertions) {
        debug!("Not running a debug build, skipping check for latest bin");

        return Ok(());
    }

    let current_exe = get_current_exe()?;
    let crate_root = get_crate_root()?;

    debug!("current_exe: {}", current_exe.display());
    debug!("crate_root: {}", crate_root.display());

    // TODO: figure out how to bring this back; the main issue is that when we are building the
    // workspace root and using generate-binutils-symlinks we no longer can tell at execution
    // time if we are running the crate root symlink or the workspace root /targets folder version
    // if !current_exe.starts_with(crate_root) {
    //    info!("opting out of ensure_latest_bin");
    //    return Ok(());
    // }

    if needs_rebuild()? {
        run_cargo_build()?;
        exec_updated_bin()?
    }

    Ok(())
}
