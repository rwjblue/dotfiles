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

pub fn generate_symlinks() -> Result<()> {
    // TODO: automatically support both debug and release profiles
    let profile = "debug";

    // Load the metadata of the workspace
    let metadata = MetadataCommand::new()
        .exec()
        .expect("Failed to load metadata");

    let workspace_root = PathBuf::from(&metadata.workspace_root);

    // The workspace's target directory
    let workspace_target_dir = workspace_root.join("target").join(profile);

    // Iterate over each package in the workspace
    for package in metadata.workspace_packages() {
        process_package(package, profile, &workspace_target_dir)?;
    }

    Ok(())
}
