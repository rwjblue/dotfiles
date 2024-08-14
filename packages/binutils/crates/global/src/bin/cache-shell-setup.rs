use anyhow::{Context, Result};
use clap::Parser;
use regex::Regex;
use std::fs::{self, File};
use std::io::{BufRead, BufReader, Write};
use std::path::Path;
use std::process::Command;

// TODO: refactor to take two arguments the source path and the destination path
// then update the logic to not mutate the source file, it just emits the new content
// to the destination file
fn process_file(file_path: &Path) -> Result<()> {
    let file = File::open(file_path).context("Failed to open file for reading")?;
    let reader = BufReader::new(file);

    let output_start_regex = Regex::new(r"# OUTPUT START: (.+)").unwrap();
    let output_end_regex = Regex::new(r"# OUTPUT END: (.+)").unwrap();

    let mut new_content = Vec::new();
    let mut skip_output_block = false;

    for line in reader.lines() {
        let line = line.context("Failed to read line")?;

        if let Some(command) = line.strip_prefix("# CMD:") {
            let trimmed_command = command.trim();

            new_content.push(format!("# CMD: {}", trimmed_command));

            let output = Command::new("sh")
                .arg("-c")
                .arg(trimmed_command)
                .output()
                .context("Failed to execute command")?;

            if output.status.success() {
                let output_str = String::from_utf8_lossy(&output.stdout);
                new_content.push(format!(
                    "# OUTPUT START: {}\n{}\n# OUTPUT END: {}",
                    trimmed_command, output_str, trimmed_command
                ));
            } else {
                eprintln!(
                    "Failed to run command '{}': {}",
                    trimmed_command,
                    String::from_utf8_lossy(&output.stderr)
                );
            }

            skip_output_block = true;
        } else if skip_output_block {
            if output_end_regex.is_match(&line) {
                skip_output_block = false;
            }
        } else if output_start_regex.is_match(&line) {
            // If we find an unexpected OUTPUT START, skip until the corresponding OUTPUT END
            skip_output_block = true;
        } else {
            new_content.push(line);
        }
    }

    let mut output_file = File::create(file_path).context("Failed to open file for writing")?;

    for line in new_content {
        writeln!(output_file, "{}", line).context("Failed to write line")?;
    }

    output_file.flush().context("Failed to flush file")?;

    Ok(())
}

fn process_directory(dir: &Path) -> Result<()> {
    let zsh_filenames = ["zshrc", "zshenv", "zprofile", "zlogin", "zlogout"];

    for entry in fs::read_dir(dir).context("Failed to read directory")? {
        let entry = entry.context("Failed to process directory entry")?;
        let path = entry.path();

        let is_zsh_file = path.extension().and_then(|s| s.to_str()) == Some("zsh");
        let is_special_zsh_file = path
            .file_name()
            .and_then(|s| s.to_str())
            .map_or(false, |name| zsh_filenames.contains(&name));

        if is_zsh_file || is_special_zsh_file {
            process_file(&path).context(format!("Failed to process file {:?}", path))?;
        }
    }
    Ok(())
}

/// cache-shell-setup
///
/// Processes .zsh files to cache environment variables by running commands
/// and saving their output. This tool speeds up your shell startup time by
/// precomputing and caching the output of commands like `brew shellenv`.
/// It processes all `.zsh` files in a specified directory, looks for specific
/// commands (e.g., `# CMD:`), executes them, and stores their output directly
/// in the `.zsh` files, ensuring the operation is idempotent.
#[derive(Parser)]
#[command(name = "cache-shell-setup")]
struct Args {
    /// Directory path to process
    #[clap(short, long, default_value = "~/src/rwjblue/dotfiles/zsh/")]
    directory: String,
}

fn main() -> Result<()> {
    let args = Args::parse();

    let directory = shellexpand::tilde(&args.directory).to_string();
    let directory = Path::new(&directory);

    process_directory(directory).context("Failed to process directory")
}

#[cfg(test)]
mod tests {
    use super::*;
    use insta::assert_snapshot;
    use std::fs::write;
    use tempfile::tempdir;

    #[test]
    fn test_process_file_with_valid_command() -> Result<()> {
        let dir = tempdir()?;
        let file_path = dir.path().join("test.zsh");

        let content = "# CMD: echo 'hello world'\n";
        write(&file_path, content)?;

        process_file(&file_path)?;

        let processed_content = fs::read_to_string(&file_path)?;
        assert_snapshot!(processed_content, @r###"
        # CMD: echo 'hello world'
        # OUTPUT START: echo 'hello world'
        hello world

        # OUTPUT END: echo 'hello world'
        "###);

        Ok(())
    }

    #[test]
    fn test_process_file_with_existing_output() -> Result<()> {
        let dir = tempdir()?;
        let file_path = dir.path().join("test.zsh");

        let content = "# CMD: echo 'hello world'\n# OUTPUT START: echo 'hello world'\nold output\n# OUTPUT END: echo 'hello world'\n";
        write(&file_path, content)?;

        process_file(&file_path)?;

        let processed_content = fs::read_to_string(&file_path)?;
        assert_snapshot!(processed_content, @r###"
        # CMD: echo 'hello world'
        # OUTPUT START: echo 'hello world'
        hello world

        # OUTPUT END: echo 'hello world'
        "###);

        Ok(())
    }

    #[test]
    fn test_process_file_with_invalid_command() -> Result<()> {
        let dir = tempdir()?;
        let file_path = dir.path().join("test.zsh");

        let content = "# CMD: invalidcommand\n";
        write(&file_path, content)?;

        // Process the file (should not panic, just print error)
        process_file(&file_path)?;

        let processed_content = fs::read_to_string(&file_path)?;

        assert_snapshot!(processed_content, @r###"
        # CMD: invalidcommand
        "###);

        Ok(())
    }
}
