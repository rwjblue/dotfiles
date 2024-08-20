use anyhow::{Context, Result};
use clap::{Parser, ValueEnum};
use std::fs::{self, File};
use std::io::{BufRead, BufReader, Write};
use std::path::{Path, PathBuf};
use std::process::Command;
use tracing::{debug, error, info, trace};
use tracing_subscriber::EnvFilter;

fn process_file<S: AsRef<Path>>(source_file: S, dest_file: S) -> Result<()> {
    let source_file = source_file.as_ref();
    let dest_file = dest_file.as_ref();

    debug!("Processing file: {}", source_file.display());

    let file = File::open(source_file).context("Failed to open file for reading")?;
    let reader = BufReader::new(file);

    let mut new_content = Vec::new();

    for line in reader.lines() {
        let line = line.context("Failed to read line")?;

        if let Some(command) = line.strip_prefix("# CMD:") {
            let trimmed_command = command.trim();

            new_content.push(format!("# CMD: {}", trimmed_command));

            trace!("Running command: {}", trimmed_command);

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
                error!(
                    "Failed to run command '{}':\n {}",
                    trimmed_command,
                    String::from_utf8_lossy(&output.stderr)
                );
            }
        } else {
            new_content.push(line);
        }
    }

    if let Some(parent) = dest_file.parent() {
        fs::create_dir_all(parent)
            .with_context(|| format!("Failed to create directories for path: {:?}", parent))?;
    }

    debug!("Writing to file: {}", dest_file.display());
    trace!("New content:\n{}", new_content.join("\n"));

    let mut output_file = File::create(dest_file)
        .with_context(|| format!("Failed to open file for writing: {}", dest_file.display()))?;

    for line in new_content {
        writeln!(output_file, "{}", line).context("Failed to write line")?;
    }

    output_file.flush().context("Failed to flush file")?;

    Ok(())
}

fn process_directory(source_dir: &Path, dest_dir: &Path) -> Result<()> {
    info!("Scanning directory: {}", source_dir.display());

    for entry in fs::read_dir(source_dir)
        .with_context(|| format!("Failed to read directory: {}", source_dir.display()))?
    {
        let entry = entry.context("Failed to process directory entry")?;
        let path = entry.path();

        if path.starts_with(dest_dir) {
            continue;
        }

        if path.is_dir() {
            let relative_path = path
                .strip_prefix(source_dir)
                .context("Failed to get relative path")?;
            let new_dest_dir = dest_dir.join(relative_path);

            fs::create_dir_all(&new_dest_dir).context("Failed to create destination directory")?;
            process_directory(&path, &new_dest_dir)
                .context(format!("Failed to process directory {:?}", path))?;
        } else {
            let relative_path = path
                .strip_prefix(source_dir)
                .context("Failed to get relative path")?;
            let dest_file = dest_dir.join(relative_path);
            process_file(&path, &dest_file)
                .context(format!("Failed to process file {:?}", path))?;
        }
    }
    Ok(())
}

/// Represents whether to clear the destination directory
#[derive(ValueEnum, Clone, Debug, PartialEq)]
enum DestinationStrategy {
    Clear,
    Merge,
}

/// cache-shell-setup
///
/// Processes .zsh files to cache environment variables by running commands
/// and saving their output. This tool speeds up your shell startup time by
/// precomputing and caching the output of commands like `brew shellenv`.
/// It processes all `.zsh` files in a specified directory, looks for specific
/// commands (e.g., `# CMD:`), executes them, and stores their output directly
/// in the `.zsh` files, ensuring the operation is idempotent.
#[derive(Parser, Debug)]
#[command(name = "cache-shell-setup")]
struct Args {
    /// Path to the configuration file. Defaults to `~/.config/binutils/config.yaml`.
    #[arg(long)]
    config_file: Option<String>,

    /// Directory path to process
    #[clap(short, long)]
    source: Option<String>,

    /// Directory path to emit the expanded output into
    #[clap(short, long)]
    destination: Option<String>,

    /// Whether to clear the destination directory before processing
    #[clap(value_enum, long, default_value_t = DestinationStrategy::Clear)]
    destination_strategy: DestinationStrategy,
}

fn run(args: Vec<String>) -> Result<()> {
    let args = Args::parse_from(args);
    let config_file = args.config_file.as_ref().map(PathBuf::from);
    let config = config::read_config(config_file)?;

    let source_dir = if let Some(source) = args.source {
        source
    } else if let Some(shell_caching) = &config.shell_caching {
        shell_caching.source.clone()
    } else {
        anyhow::bail!("No source directory provided. Either use the --source flag or set it in the config file. \nArgs: {:?} \nConfig: {:?}", args, config);
    };

    let destination_dir = if let Some(destination) = args.destination {
        destination
    } else if let Some(shell_caching) = &config.shell_caching {
        shell_caching.destination.clone()
    } else {
        anyhow::bail!("No source directory provided. Either use the --source flag or set it in the config file");
    };

    let source_dir = shellexpand::tilde(&source_dir).to_string();
    let source_dir = Path::new(&source_dir);

    let dest_dir = shellexpand::tilde(&destination_dir).to_string();
    let dest_dir = Path::new(&dest_dir);

    if args.destination_strategy == DestinationStrategy::Clear {
        info!("Clearing destination directory");
        fs::remove_dir_all(dest_dir).context("Failed to clear destination directory")?;
    }

    process_directory(source_dir, dest_dir).context("Failed to process directory")
}

fn main() -> Result<()> {
    // Initialize tracing, use `info` by default
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .init();

    latest_bin::ensure_latest_bin()?;

    let args: Vec<String> = std::env::args().collect();
    run(args)
}

#[cfg(test)]
mod tests {
    use super::*;
    use insta::{assert_debug_snapshot, assert_snapshot};
    use std::collections::BTreeMap;
    use std::fs::write;
    use tempfile::tempdir;
    use test_utils::setup_test_environment;

    #[test]
    fn test_process_file_with_valid_command() -> Result<()> {
        let dir = tempdir()?;
        let source_file = dir.path().join("test.zsh");
        let dest_file = dir.path().join("output.zsh");

        let content = "# CMD: echo 'hello world'\n";
        write(&source_file, content)?;

        process_file(&source_file, &dest_file)?;

        let source_contents = fs::read_to_string(&source_file)?;

        assert_snapshot!(source_contents, @r###"
        # CMD: echo 'hello world'
        "###);

        let processed_content = fs::read_to_string(&dest_file)?;
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
        let source_file = dir.path().join("test.zsh");
        let dest_file = dir.path().join("output.zsh");

        write(&source_file, "# CMD: echo 'hello world'\n")?;
        write(&dest_file, "# CMD: echo 'hello world'\n# OUTPUT START: echo 'hello world'\nold output\n# OUTPUT END: echo 'hello world'\n")?;

        process_file(&source_file, &dest_file)?;

        let source_contents = fs::read_to_string(&source_file)?;

        assert_snapshot!(source_contents, @r###"
        # CMD: echo 'hello world'
        "###);

        let processed_content = fs::read_to_string(&dest_file)?;
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
        let source_file = dir.path().join("test.zsh");
        let dest_file = dir.path().join("output.zsh");

        let content = "# CMD: invalidcommand\n";
        write(&source_file, content)?;

        // Process the file (should not panic, just print error)
        process_file(&source_file, &dest_file)?;

        let source_contents = fs::read_to_string(&source_file)?;

        assert_snapshot!(source_contents, @r###"
        # CMD: invalidcommand
        "###);

        let processed_content = fs::read_to_string(&dest_file)?;

        assert_snapshot!(processed_content, @r###"
        # CMD: invalidcommand
        "###);

        Ok(())
    }

    #[test]
    fn test_process_directory() {
        let temp_dir = tempdir().unwrap();
        let base_dir = temp_dir.path();

        let source_files: BTreeMap<String, String> = BTreeMap::from([
            (
                "zsh/zshrc".to_string(),
                "# CMD: echo 'hello world'\n".to_string(),
            ),
            (
                "zsh/plugins/thing.zsh".to_string(),
                "# CMD: echo 'goodbye world'\n".to_string(),
            ),
        ]);

        fixturify::write(base_dir, source_files).unwrap();

        let source_dir = base_dir.join("zsh");
        let dest_dir = base_dir.join("zsh/dist");

        process_directory(&source_dir, &dest_dir).unwrap();

        let file_map = fixturify::read(base_dir).unwrap();

        assert_debug_snapshot!(file_map, @r###"
        {
            "zsh/dist/plugins/thing.zsh": "# CMD: echo 'goodbye world'\n# OUTPUT START: echo 'goodbye world'\ngoodbye world\n\n# OUTPUT END: echo 'goodbye world'\n",
            "zsh/dist/zshrc": "# CMD: echo 'hello world'\n# OUTPUT START: echo 'hello world'\nhello world\n\n# OUTPUT END: echo 'hello world'\n",
            "zsh/plugins/thing.zsh": "# CMD: echo 'goodbye world'\n",
            "zsh/zshrc": "# CMD: echo 'hello world'\n",
        }
        "###)
    }

    #[test]
    fn test_run_with_args() {
        let env = setup_test_environment();

        let source_files: BTreeMap<String, String> = BTreeMap::from([
            (
                "src/rwjblue/dotfiles/zsh/zshrc".to_string(),
                "# CMD: echo 'hello world'\n".to_string(),
            ),
            (
                "src/rwjblue/dotfiles/zsh/plugins/thing.zsh".to_string(),
                "# CMD: echo 'goodbye world'\n".to_string(),
            ),
            (
                "src/rwjblue/dotfiles/zsh/dist/plugins/thing.zsh".to_string(),
                "# CMD: echo 'goodbye world'\n# OLD OUTPUT SHOULD BE DELETED".to_string(),
            ),
        ]);

        fixturify::write(&env.home, source_files).unwrap();

        run(vec![
            "cache-shell-setup".to_string(),
            "--source=~/src/rwjblue/dotfiles/zsh".to_string(),
            "--destination=~/src/rwjblue/dotfiles/zsh/dist".to_string(),
        ])
        .unwrap();

        let file_map = fixturify::read(&env.home).unwrap();

        assert_debug_snapshot!(file_map, @r###"
        {
            "src/rwjblue/dotfiles/zsh/dist/plugins/thing.zsh": "# CMD: echo 'goodbye world'\n# OUTPUT START: echo 'goodbye world'\ngoodbye world\n\n# OUTPUT END: echo 'goodbye world'\n",
            "src/rwjblue/dotfiles/zsh/dist/zshrc": "# CMD: echo 'hello world'\n# OUTPUT START: echo 'hello world'\nhello world\n\n# OUTPUT END: echo 'hello world'\n",
            "src/rwjblue/dotfiles/zsh/plugins/thing.zsh": "# CMD: echo 'goodbye world'\n",
            "src/rwjblue/dotfiles/zsh/zshrc": "# CMD: echo 'hello world'\n",
        }
        "###)
    }

    #[test]
    fn test_run_with_config() {
        let env = setup_test_environment();

        let config_path = &env.config_file;
        fs::write(
            config_path,
            r###"return { shell_caching = { source = "~/other-path/zsh", destination = "~/other-path/zsh/dist" } }"###,
        )
        .expect("Could not write to config file");

        let source_files: BTreeMap<String, String> = BTreeMap::from([
            (
                "other-path/zsh/zshrc".to_string(),
                "# CMD: echo 'hello world'\n".to_string(),
            ),
            (
                "other-path/zsh/plugins/thing.zsh".to_string(),
                "# CMD: echo 'goodbye world'\n".to_string(),
            ),
            (
                "other-path/zsh/dist/plugins/thing.zsh".to_string(),
                "# CMD: echo 'goodbye world'\n# OLD OUTPUT SHOULD BE DELETED".to_string(),
            ),
        ]);

        fixturify::write(&env.home, source_files).unwrap();

        run(vec![]).unwrap();

        let file_map = fixturify::read(&env.home).unwrap();

        assert_debug_snapshot!(file_map, @r###"
        {
            ".config/binutils/config.lua": "return { shell_caching = { source = \"~/other-path/zsh\", destination = \"~/other-path/zsh/dist\" } }",
            "other-path/zsh/dist/plugins/thing.zsh": "# CMD: echo 'goodbye world'\n# OUTPUT START: echo 'goodbye world'\ngoodbye world\n\n# OUTPUT END: echo 'goodbye world'\n",
            "other-path/zsh/dist/zshrc": "# CMD: echo 'hello world'\n# OUTPUT START: echo 'hello world'\nhello world\n\n# OUTPUT END: echo 'hello world'\n",
            "other-path/zsh/plugins/thing.zsh": "# CMD: echo 'goodbye world'\n",
            "other-path/zsh/zshrc": "# CMD: echo 'hello world'\n",
        }
        "###)
    }

    #[test]
    fn test_run_with_merging() {
        let env = setup_test_environment();

        let source_files: BTreeMap<String, String> = BTreeMap::from([
            (
                "src/rwjblue/dotfiles/zsh/zshrc".to_string(),
                "# CMD: echo 'hello world'\n".to_string(),
            ),
            (
                "src/rwjblue/dotfiles/zsh/plugins/thing.zsh".to_string(),
                "# CMD: echo 'goodbye world'\n".to_string(),
            ),
            (
                "src/rwjblue/dotfiles/zsh/dist/plugins/thing.zsh".to_string(),
                "# CMD: echo 'goodbye world'\n# OLD OUTPUT SHOULD BE DELETED".to_string(),
            ),
            (
                "src/rwjblue/dotfiles/zsh/dist/plugins/weird-other-thing.zsh".to_string(),
                "# HAHAHA WTF IS THIS?!?! DO NOT WORRY ABOUT".to_string(),
            ),
        ]);

        fixturify::write(&env.home, source_files).unwrap();

        run(vec![
            "cache-shell-setup".to_string(),
            "--source=~/src/rwjblue/dotfiles/zsh".to_string(),
            "--destination=~/src/rwjblue/dotfiles/zsh/dist".to_string(),
            "--destination-strategy=merge".into(),
        ])
        .unwrap();

        let file_map = fixturify::read(&env.home).unwrap();

        assert_debug_snapshot!(file_map, @r###"
        {
            "src/rwjblue/dotfiles/zsh/dist/plugins/thing.zsh": "# CMD: echo 'goodbye world'\n# OUTPUT START: echo 'goodbye world'\ngoodbye world\n\n# OUTPUT END: echo 'goodbye world'\n",
            "src/rwjblue/dotfiles/zsh/dist/plugins/weird-other-thing.zsh": "# HAHAHA WTF IS THIS?!?! DO NOT WORRY ABOUT",
            "src/rwjblue/dotfiles/zsh/dist/zshrc": "# CMD: echo 'hello world'\n# OUTPUT START: echo 'hello world'\nhello world\n\n# OUTPUT END: echo 'hello world'\n",
            "src/rwjblue/dotfiles/zsh/plugins/thing.zsh": "# CMD: echo 'goodbye world'\n",
            "src/rwjblue/dotfiles/zsh/zshrc": "# CMD: echo 'hello world'\n",
        }
        "###)
    }
}

// TODO: Add support to handle race conditions: currently sheldon source reads the files in
// zsh/dist *but* we also have `# CMD: sheldon source` (which reads those files)
// Try adding "passes" so you can `# CMD(1): sheldon source` (where the default is "pass 0")
// and each pass would get flushed to disk together -- this does make a z-index war kinda thing
// but in practice who cares?
