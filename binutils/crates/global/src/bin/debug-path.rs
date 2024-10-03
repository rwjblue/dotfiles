use anyhow::{Context, Result};
use clap::Parser;
use std::env;
use std::fs;
use std::path::{Path, PathBuf};

use tree_sitter::{Node, Parser as TSParser, Query, QueryCursor};

/// A tool to debug and inspect the $PATH environment variable.
#[derive(Parser)]
#[clap(author, version, about)]
struct Cli {}

fn main() -> Result<()> {
    // Initialize tracing subscriber (optional)
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("off")),
        )
        .init();

    // Parse command-line arguments (if any)
    let _cli = Cli::parse();

    // Get the user's home directory
    let home_dir = env::var("HOME").context("Failed reading $HOME")?;

    // List of Zsh configuration files in the order they are processed
    let config_files: Vec<PathBuf> = vec![
        "/etc/zshenv",
        "~/.zshenv",
        "/etc/zprofile",
        "/etc/paths",   // Add /etc/paths after /etc/zprofile
        "/etc/paths.d", // Add /etc/paths.d after /etc/paths
        "~/.zprofile",
        "/etc/zshrc",
        "~/.zshrc",
        "/etc/zlogin",
        "~/.zlogin",
    ]
    .into_iter()
    .map(|p| {
        // Replace '~' with the actual home directory
        if p.starts_with("~/") {
            PathBuf::from(p.replacen('~', &home_dir, 1))
        } else {
            PathBuf::from(p)
        }
    })
    .collect();

    // Process each configuration file
    for config_file in &config_files {
        let path = config_file;

        // Check if the file exists
        if path.exists() {
            println!("Processing file: {}", path.display());

            if path == Path::new("/etc/paths") {
                // Process /etc/paths
                process_paths_file(path)?;
            } else if path == Path::new("/etc/paths.d") {
                // Process each file in /etc/paths.d/
                for entry in fs::read_dir(path).context("Failed to read /etc/paths.d/")? {
                    let entry = entry?;
                    let file_path = entry.path();
                    if file_path.is_file() {
                        process_paths_file(&file_path)?;
                    }
                }
            } else {
                // Process as shell script using Tree-sitter
                process_shell_file(path)?;
            }
        } else {
            println!("File does not exist: {}", path.display());
        }
    }

    Ok(())
}

/// Function to process /etc/paths and files in /etc/paths.d/
fn process_paths_file(path: &Path) -> Result<()> {
    // Read the file content
    let content =
        fs::read_to_string(path).with_context(|| format!("Failed to read {}", path.display()))?;

    // Process each line (directory)
    for (line_number, line) in content.lines().enumerate() {
        let line = line.trim();
        if !line.is_empty() {
            println!(
                "{}:{}: Adds '{}' to PATH",
                path.display(),
                line_number + 1,
                line
            );
        }
    }
    Ok(())
}

fn process_shell_file(path: &Path) -> Result<()> {
    // Initialize Tree-sitter parser for Bash (Zsh is similar enough for parsing)
    let language = tree_sitter_bash::LANGUAGE;
    let mut parser = TSParser::new();
    parser.set_language(&language.into())?;

    // Tree-sitter query to find assignments to PATH
    let query_str = r#"
        (
            (variable_assignment
                name: (variable_name) @name
                value: (_) @value)
            (#eq? @name "PATH")
        )
    "#;
    let query = Query::new(&language.into(), query_str)?;
    // Read the file content
    let source_code =
        fs::read_to_string(path).with_context(|| format!("Failed to read {}", path.display()))?;

    // Parse the source code
    let tree = parser
        .parse(&source_code, None)
        .with_context(|| format!("Failed to parse {}", path.display()))?;

    // Execute the query
    let mut query_cursor = QueryCursor::new();
    let matches = query_cursor.matches(&query, tree.root_node(), source_code.as_bytes());

    // Collect line offsets for mapping byte offsets to line numbers
    let line_offsets: Vec<_> = source_code.match_indices('\n').collect();

    for m in matches {
        for capture in m.captures {
            if query.capture_names()[capture.index as usize] == "value" {
                let node = capture.node;
                let start_byte = node.start_byte();
                let line_number = get_line_number(&line_offsets, start_byte) + 1; // Lines are zero-indexed
                let line_content = get_line_content(&source_code, node);

                println!(
                    "{}:{}: {}",
                    path.display(),
                    line_number,
                    line_content.trim_end()
                );
            }
        }
    }

    Ok(())
}
// Helper function to get the line number from byte offset
fn get_line_number(line_offsets: &[(usize, &str)], byte_offset: usize) -> usize {
    match line_offsets.binary_search_by(|&(offset, _)| offset.cmp(&byte_offset)) {
        Ok(index) => index,
        Err(index) => index,
    }
}

// Helper function to get the line content where the node is located
fn get_line_content<'a>(source_code: &'a str, node: Node) -> &'a str {
    let start = source_code[..node.start_byte()]
        .rfind('\n')
        .map(|pos| pos + 1)
        .unwrap_or(0);
    let end = source_code[node.end_byte()..]
        .find('\n')
        .map(|pos| node.end_byte() + pos)
        .unwrap_or(source_code.len());

    &source_code[start..end]
}
