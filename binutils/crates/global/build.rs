use std::env;
use std::fs;
use std::os::unix::fs::symlink;
use std::path::{Path, PathBuf};

fn main() {
    // Get the workspace root directory from the CARGO_MANIFEST_DIR
    let manifest_dir = env::var("CARGO_MANIFEST_DIR").expect("CARGO_MANIFEST_DIR not defined");
    let crate_root = PathBuf::from(&manifest_dir);

    // Get the build type (debug or release)
    let profile = env::var("PROFILE").expect("PROFILE not defined");

    // Construct the target directories for the workspace root and crate root
    let workspace_target_dir = crate_root.join("..").join("target").join(&profile);
    let crate_target_dir = crate_root.join("target").join(&profile);

    // Create the target directory in the crate if it doesn't exist
    if !crate_target_dir.exists() {
        fs::create_dir_all(&crate_target_dir).expect("Failed to create crate target directory");
    }

    // Path to the src/bin directory
    let bin_dir = crate_root.join("src/bin");

    // Iterate over each file in src/bin
    if let Ok(entries) = fs::read_dir(bin_dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_file() {
                if let Some(file_name) = path.file_stem() {
                    let file_name_str = file_name.to_string_lossy();

                    // Construct the source and destination paths for the symlink
                    let source_path = workspace_target_dir.join(&*file_name_str);
                    let dest_path = crate_target_dir.join(&*file_name_str);

                    // Print debugging information
                    println!("Source: {}", source_path.display());
                    println!("Destination: {}", dest_path.display());

                    // Create the symlink (ignore if it already exists)
                    if !dest_path.exists() {
                        symlink(&source_path, &dest_path).expect("Failed to create symlink");
                        println!(
                            "Symlink created: {} -> {}",
                            dest_path.display(),
                            source_path.display()
                        );
                    } else {
                        println!("Symlink already exists: {}", dest_path.display());
                    }
                }
            }
        }
    } else {
        println!("No binaries found in src/bin/");
    }
}
