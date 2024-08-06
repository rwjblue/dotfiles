use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};
use walkdir::WalkDir;

pub fn get_max_mod_time<P: AsRef<Path>>(dir: P) -> SystemTime {
    let mut max_mod_time = UNIX_EPOCH;
    for entry in WalkDir::new(dir) {
        let entry = entry.unwrap();
        if entry.file_type().is_file() {
            let metadata = fs::metadata(entry.path()).unwrap();
            let mod_time = metadata.modified().unwrap();
            if mod_time > max_mod_time {
                max_mod_time = mod_time;
            }
        }
    }
    max_mod_time
}

pub fn is_build_up_to_date() -> bool {
    let (crate_root, build_output_dir) = get_crate_root_and_target_dir();

    let max_source_mod_time = get_max_mod_time(crate_root);
    let max_target_mod_time = get_max_mod_time(build_output_dir);

    max_target_mod_time >= max_source_mod_time
}

fn get_crate_root_and_target_dir() -> (PathBuf, PathBuf) {
    let crate_root = env::var("CARGO_MANIFEST_DIR").expect("CARGO_MANIFEST_DIR is not set");
    let out_dir = env::var("OUT_DIR").expect("OUT_DIR is not set");
    let target_dir = Path::new(&out_dir)
        .parent()
        .and_then(|p| p.parent())
        .expect("Could not determine target directory")
        .to_path_buf();

    (PathBuf::from(crate_root), target_dir)
}
