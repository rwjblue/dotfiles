use anyhow::{Context, Result};
use nix::unistd::execv;
use std::env;
use std::ffi::CString;
use std::fs;
use std::path::Path;
use std::process::Command;
use std::time::SystemTime;
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

pub fn needs_rebuild() -> Result<bool> {
    let crate_root = env!("CARGO_MANIFEST_DIR");
    let current_exe = env::current_exe().context("Failed to get the current executable path")?;

    debug!("crate_root: {}", crate_root);
    debug!("current_exe: {}", current_exe.to_string_lossy());

    let exe_mod_time = modified_time(&current_exe)?;
    let needs_rebuild = has_updated_files(crate_root, exe_mod_time)?;

    info!("needs_rebuild: {}", needs_rebuild);

    Ok(needs_rebuild)
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

pub fn exec_updated_bin() -> Result<()> {
    let current_exe = env::current_exe().context("Failed to get current executable path")?;

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
    if needs_rebuild()? {
        run_cargo_build()?;
        exec_updated_bin()?
    }

    Ok(())
}
