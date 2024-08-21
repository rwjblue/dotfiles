use anyhow::{Context, Result};
use cargo_metadata::{MetadataCommand, Package};

use std::fs;
use std::os::unix::fs::symlink;
use std::path::{Path, PathBuf};
use tracing::{debug, info};

fn process_package(package: &Package, profile: &str, workspace_target_dir: &Path) -> Result<()> {
    info!(
        "Processing {} from {}",
        &package.name, &package.manifest_path
    );

    let crate_root = PathBuf::from(&package.manifest_path)
        .parent()
        .unwrap()
        .to_path_buf();

    let crate_target_dir = crate_root.join("target").join(profile);

    // TODO: add option (threaded through the bin) to opt-out of clearing
    if crate_target_dir.exists() {
        info!(
            "{}/target already exists, removing it",
            &crate_target_dir.display()
        );

        fs::remove_dir_all(&crate_target_dir).with_context(|| {
            format!(
                "Failed to remove existing crate target directory: {}",
                crate_target_dir.display()
            )
        })?;
    }

    fs::create_dir_all(&crate_target_dir).with_context(|| {
        format!(
            "Failed to create crate target directory: {}",
            crate_target_dir.display()
        )
    })?;

    for target in package.targets.iter() {
        if target.kind.contains(&"bin".to_string()) {
            let source_path = workspace_target_dir.join(&target.name);
            let dest_path = crate_target_dir.join(&target.name);

            info!("\tProcessing binary {}", target.name,);

            debug!(
                "\t\tLinking from {} -> {}",
                source_path.display(),
                dest_path.display()
            );

            if !dest_path.exists() {
                symlink(&source_path, &dest_path).context("Failed to create symlink")?;
            } else {
                debug!("\t\tSymlink already exists: {}", dest_path.display());
            }
        }
    }

    Ok(())
}

pub fn generate_symlinks(working_dir: Option<PathBuf>) -> Result<()> {
    info!("Generating crate local target symlinks for local workspace packages");
    let working_dir = working_dir.unwrap_or(PathBuf::from("."));

    // TODO: automatically support both debug and release profiles
    let profile = "debug";

    let metadata = MetadataCommand::new()
        .current_dir(working_dir)
        .exec()
        .expect("Failed to load metadata");

    let workspace_root = PathBuf::from(&metadata.workspace_root);

    let workspace_target_dir = workspace_root.join("target").join(profile);

    for package in metadata.workspace_packages() {
        process_package(package, profile, &workspace_target_dir)?;
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;
    use test_utils::{create_workspace_with_packages, FakeBin, FakePackage};

    #[test]
    fn test_process_package_target_exists() {
        let temp_dir = tempdir().unwrap();
        let packages = vec![FakePackage {
            name: "test_package".to_string(),
            bins: vec![FakeBin {
                name: "hello_world".to_string(),
                contents: None,
            }],
        }];
        create_workspace_with_packages(temp_dir.path(), packages);

        let profile = "debug";

        let package_dir = temp_dir.path().join("test_package");
        let crate_target_dir = package_dir.join("target").join(profile);

        generate_symlinks(Some(temp_dir.path().to_path_buf())).unwrap();

        assert!(crate_target_dir.join("hello_world").exists());
    }

    #[test]
    fn test_test_package_bin_is_executable() {
        let temp_dir = tempdir().unwrap();
        let packages = vec![FakePackage {
            name: "test_package".to_string(),
            bins: vec![FakeBin {
                name: "hello_world".to_string(),
                contents: None,
            }],
        }];
        create_workspace_with_packages(temp_dir.path(), packages);

        let profile = "debug";

        let package_dir = temp_dir.path().join("test_package");
        let crate_target_dir = package_dir.join("target").join(profile);

        generate_symlinks(Some(temp_dir.path().to_path_buf())).unwrap();

        let bin_path = crate_target_dir.join("hello_world");
        assert!(bin_path.exists(), "precond - file exists");

        let output = std::process::Command::new(bin_path.clone())
            .output()
            .expect("failed to execute process");

        assert!(
            output.status.success(),
            "process did not exit successfully: {}",
            output.status
        );

        let stdout = String::from_utf8_lossy(&output.stdout);
        assert_eq!(
            stdout.trim(),
            format!("\"{}\"", bin_path.to_string_lossy().trim()),
            "stdout does not match expected output"
        );
    }
}
