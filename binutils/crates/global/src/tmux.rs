use anyhow::Result;
use std::{collections::BTreeMap, path::PathBuf, process::Command};
use tracing::debug;

use config::{Command as ConfigCommand, Config, Window};

/// `TmuxOptions` is a trait for managing various options for working with these tmux utilities.
///
/// It provides methods to check if the current run is a dry run, if it's in debug mode, and if it should attach to tmux.
pub trait TmuxOptions {
    /// Checks if the current run is a dry run.
    ///
    /// In a dry run, commands are not actually executed. Instead, they are just printed to the console.
    /// This is useful for testing and debugging.
    fn is_dry_run(&self) -> bool;

    /// Checks if the current run is in debug mode.
    fn is_debug(&self) -> bool;

    /// Provides the socket name of the tmux server to attach to.
    ///
    /// If this returns `None`, the default socket name will be used.
    fn socket_name(&self) -> Option<String>;

    /// Decides if we should attach to tmux in the running terminal.
    ///
    /// Returns `Some(true)` if we should attach, `Some(false)` if we should not, and `None` if the decision is left to the default behavior.
    fn should_attach(&self) -> Option<bool>;

    fn config_file(&self) -> Option<PathBuf>;
}

pub fn in_tmux() -> bool {
    std::env::var("TMUX").is_ok()
}

fn get_socket_name(options: &impl TmuxOptions) -> String {
    options
        .socket_name()
        .unwrap_or_else(|| "default".to_string())
}

pub fn startup_tmux(config: Config, options: &impl TmuxOptions) -> Result<Vec<String>> {
    let mut current_state = gather_tmux_state(options);
    let mut commands = vec![];

    match config.tmux {
        Some(tmux) => {
            for session in tmux.sessions {
                for window in session.windows {
                    let commands_executed =
                        ensure_window(&session.name, &window, &mut current_state, options)?;

                    for command in commands_executed {
                        commands.push(command_to_string(&command));
                    }
                }
            }
        }
        None => {
            debug!("No tmux configuration found, skipping tmux setup");
        }
    }

    Ok(commands)
}

fn ensure_window(
    session_name: &str,
    window: &Window,
    current_state: &mut TmuxState,
    options: &impl TmuxOptions,
) -> Result<Vec<Command>> {
    let socket_name = get_socket_name(options);
    let mut commands_executed = vec![];

    if let Some(windows) = current_state.get(session_name) {
        if windows.contains(&window.name) {
            // Window already exists, do nothing
        } else {
            // Window does not exist, create it
            let mut cmd = Command::new("tmux");
            cmd.arg("-L")
                .arg(&socket_name)
                .arg("new-window")
                .arg("-t")
                .arg(session_name)
                .arg("-n")
                .arg(&window.name);

            if let Some(path) = &window.path {
                cmd.arg("-c").arg(path);
            }

            commands_executed.push(run_command(cmd, options)?);
            commands_executed.extend(execute_command(session_name, window, options)?);
        }
    } else {
        // Session does not exist, create it and the window
        let mut cmd = Command::new("tmux");
        cmd.arg("-L")
            .arg(&socket_name)
            .arg("new-session")
            .arg("-d")
            .arg("-s")
            .arg(session_name)
            .arg("-n")
            .arg(&window.name);

        if let Some(path) = &window.path {
            cmd.arg("-c").arg(path);
        }

        commands_executed.push(run_command(cmd, options)?);
        commands_executed.extend(execute_command(session_name, window, options)?);
    }

    Ok(commands_executed)
}

fn execute_command(
    session_name: &str,
    window: &Window,
    options: &impl TmuxOptions,
) -> Result<Vec<Command>> {
    let mut commands_executed = vec![];

    if let Some(command) = &window.command {
        match command {
            ConfigCommand::Single(command) => {
                let mut cmd = Command::new("tmux");
                cmd.arg("-L")
                    .arg(get_socket_name(options))
                    .arg("send-keys")
                    .arg("-t")
                    .arg(format!("{}:{}", session_name, window.name))
                    .arg(command)
                    .arg("Enter");

                let cmd = run_command(cmd, options)?;
                commands_executed.push(cmd);
            }
            ConfigCommand::Multiple(commands) => {
                for command in commands {
                    let mut cmd = Command::new("tmux");
                    cmd.arg("-L")
                        .arg(get_socket_name(options))
                        .arg("send-keys")
                        .arg("-t")
                        .arg(format!("{}:{}", session_name, window.name))
                        .arg(command)
                        .arg("Enter");

                    let cmd = run_command(cmd, options)?;
                    commands_executed.push(cmd);
                }
            }
        }
    }

    Ok(commands_executed)
}

type TmuxState = BTreeMap<String, Vec<String>>;

/// Runs `tmux list-sessions -F #{session_name}` to gather sessions, then for each session
/// runs `tmux list-windows -F #{window_name}` and returns a HashMap where the keys are session
/// names and the values is an array of the window names.
fn gather_tmux_state(options: &impl TmuxOptions) -> TmuxState {
    let mut state = BTreeMap::new();

    let socket_name = get_socket_name(options);

    let sessions_output = Command::new("tmux")
        .arg("-L")
        .arg(&socket_name)
        .arg("list-sessions")
        .arg("-F")
        .arg("#{session_name}")
        .output()
        .expect("Failed to execute command");

    let sessions = String::from_utf8(sessions_output.stdout).unwrap();
    for session in sessions.lines() {
        let windows_output = Command::new("tmux")
            .arg("-L")
            .arg(&socket_name)
            .arg("list-windows")
            .arg("-F")
            .arg("#{window_name}")
            .arg("-t")
            .arg(session)
            .output()
            .expect("Failed to execute command");

        let windows = String::from_utf8(windows_output.stdout).unwrap();
        state.insert(
            session.to_string(),
            windows
                .lines()
                .map(|s| s.to_string())
                .collect::<Vec<String>>(),
        );
    }

    state
}

fn run_command(mut cmd: Command, opts: &impl TmuxOptions) -> Result<Command> {
    if opts.is_dry_run() {
        println!("{}", command_to_string(&cmd));
    } else {
        cmd.output()?;
    }

    Ok(cmd)
}

fn command_to_string(cmd: &Command) -> String {
    let mut cmd_string = String::new();

    if let Some(program) = cmd.get_program().to_str() {
        cmd_string.push_str(program);
    }

    for arg in cmd.get_args() {
        if let Some(arg_str) = arg.to_str() {
            cmd_string.push(' ');
            cmd_string.push_str(arg_str);
        }
    }

    cmd_string
}

#[cfg(test)]
mod tests {
    use std::{
        collections::HashMap,
        path::Path,
        thread::sleep,
        time::{Duration, Instant},
    };

    use anyhow::Result;
    use insta::{assert_debug_snapshot, assert_yaml_snapshot};
    use rand::{distributions::Alphanumeric, Rng};
    use tempfile::tempdir;

    use super::*;
    use config::{Session, Tmux, Window};

    struct TestingTmuxOptions {
        dry_run: bool,
        debug: bool,
        attach: Option<bool>,
        socket_name: String,
        _config_file: Option<PathBuf>,
    }
    impl TmuxOptions for TestingTmuxOptions {
        fn is_dry_run(&self) -> bool {
            self.dry_run
        }

        fn is_debug(&self) -> bool {
            self.debug
        }

        fn should_attach(&self) -> Option<bool> {
            self.attach
        }

        fn socket_name(&self) -> Option<String> {
            Some(self.socket_name.clone())
        }

        fn config_file(&self) -> Option<PathBuf> {
            None
        }
    }

    impl Drop for TestingTmuxOptions {
        fn drop(&mut self) {
            kill_tmux_server(self).unwrap();
        }
    }

    fn generate_socket_name() -> String {
        let rng = rand::thread_rng();
        let socket_name: String = rng
            .sample_iter(&Alphanumeric)
            .take(30)
            .map(char::from)
            .collect();
        socket_name
    }

    fn create_tmux_session(
        session_name: &str,
        window_name: &str,
        options: &impl TmuxOptions,
    ) -> Result<(), std::io::Error> {
        let socket_name = get_socket_name(options);

        // Create the session with the initial window
        let _ = Command::new("tmux")
            .arg("-L")
            .arg(socket_name)
            .arg("new-session")
            .arg("-d")
            .arg("-s")
            .arg(session_name)
            .arg("-n")
            .arg(window_name)
            .status()?;

        assert!(tmux_server_running(options));

        Ok(())
    }

    fn kill_tmux_server(options: &impl TmuxOptions) -> Result<()> {
        let socket_name = get_socket_name(options);

        let _ = Command::new("tmux")
            .arg("-L")
            .arg(socket_name)
            .arg("kill-server")
            .status()?;

        Ok(())
    }

    fn tmux_server_running(options: &impl TmuxOptions) -> bool {
        let socket_name = get_socket_name(options);

        Command::new("tmux")
            .arg("-L")
            .arg(socket_name)
            .arg("has-session")
            .status()
            .map(|status| status.success())
            .unwrap_or(false)
    }

    fn build_testing_options() -> TestingTmuxOptions {
        let options = TestingTmuxOptions {
            dry_run: false,
            debug: false,
            attach: None,
            socket_name: generate_socket_name(),
            _config_file: None,
        };

        assert!(
            !tmux_server_running(&options),
            "precond - tmux server should not be running on randomized socket name"
        );

        options
    }

    fn sanitize_commands_executed(
        commands: Vec<String>,
        options: &TestingTmuxOptions,
        additional_replacements: Option<HashMap<String, String>>,
    ) -> Vec<String> {
        commands
            .iter()
            .map(|command| {
                let mut updated_command = command.replace(&options.socket_name, "[SOCKET_NAME]");
                if let Some(replacements) = &additional_replacements {
                    for (key, value) in replacements {
                        updated_command = updated_command.replace(key, value);
                    }
                }
                updated_command
            })
            .collect()
    }

    fn wait_for_file(path: &Path, message: String) {
        let start = Instant::now();
        let timeout = Duration::from_secs(2);

        loop {
            // Check if the file exists
            if path.exists() {
                break;
            }

            // Sleep for 10ms
            sleep(Duration::from_millis(10));

            // Check if the elapsed time is greater than the timeout
            if start.elapsed() > timeout {
                panic!("{}", message);
            }
        }
    }

    #[test]
    fn test_in_tmux_within_tmux() {
        temp_env::with_var(
            "TMUX",
            Some("/private/tmp/tmux-23547/default,39774,0"),
            || {
                assert!(in_tmux());
            },
        );
    }

    #[test]
    fn test_in_tmux_outside_tmux() {
        temp_env::with_var("TMUX", None::<String>, || {
            assert!(!in_tmux());
        });
    }

    #[test]
    fn test_gather_tmux_state() -> Result<()> {
        let options = build_testing_options();

        create_tmux_session("foo", "bar", &options)?;

        assert_debug_snapshot!(gather_tmux_state(&options), @r###"
        {
            "foo": [
                "bar",
            ],
        }
        "###);

        create_tmux_session("baz", "qux", &options)?;

        assert_debug_snapshot!(gather_tmux_state(&options), @r###"
        {
            "baz": [
                "qux",
            ],
            "foo": [
                "bar",
            ],
        }
        "###);

        Ok(())
    }

    #[test]
    fn test_creates_all_windows_when_server_is_not_started() -> Result<()> {
        let options = build_testing_options();
        let config = Config {
            tmux: Some(Tmux {
                sessions: vec![Session {
                    name: "foo".to_string(),
                    windows: vec![Window {
                        name: "bar".to_string(),
                        path: None,
                        command: None,
                    }],
                }],
            }),
        };
        let commands = startup_tmux(config, &options)?;
        let commands = sanitize_commands_executed(commands, &options, None);

        assert_yaml_snapshot!(commands, @r###"
        ---
        - "tmux -L [SOCKET_NAME] new-session -d -s foo -n bar"
        "###);

        assert_debug_snapshot!(gather_tmux_state(&options), @r###"
        {
            "foo": [
                "bar",
            ],
        }
        "###);

        Ok(())
    }

    #[test]
    fn test_creates_missing_windows_when_server_is_already_started() -> Result<()> {
        let options = build_testing_options();

        create_tmux_session("foo", "baz", &options)?;

        let config = Config {
            tmux: Some(Tmux {
                sessions: vec![Session {
                    name: "foo".to_string(),
                    windows: vec![Window {
                        name: "bar".to_string(),
                        path: None,
                        command: None,
                    }],
                }],
            }),
        };

        let commands = startup_tmux(config, &options)?;
        let commands = sanitize_commands_executed(commands, &options, None);

        assert_yaml_snapshot!(commands, @r###"
        ---
        - "tmux -L [SOCKET_NAME] new-window -t foo -n bar"
        "###);

        assert_debug_snapshot!(gather_tmux_state(&options), @r###"
        {
            "foo": [
                "baz",
                "bar",
            ],
        }
        "###);

        Ok(())
    }

    #[test]
    fn test_does_nothing_if_already_started() -> Result<()> {
        let options = build_testing_options();

        create_tmux_session("foo", "bar", &options)?;

        assert_debug_snapshot!(gather_tmux_state(&options), @r###"
        {
            "foo": [
                "bar",
            ],
        }
        "###);

        let config = Config {
            tmux: Some(Tmux {
                sessions: vec![Session {
                    name: "foo".to_string(),
                    windows: vec![Window {
                        name: "bar".to_string(),
                        path: None,
                        command: None,
                    }],
                }],
            }),
        };
        let commands = startup_tmux(config, &options)?;
        let commands = sanitize_commands_executed(commands, &options, None);

        assert_yaml_snapshot!(commands, @r###"
        ---
        []
        "###);

        assert_debug_snapshot!(gather_tmux_state(&options), @r###"
        {
            "foo": [
                "bar",
            ],
        }
        "###);

        Ok(())
    }

    #[test]
    fn test_invokes_command_when_window_is_created() -> Result<()> {
        let options = build_testing_options();

        let temp_dir = tempdir().expect("Failed to create a temporary directory");
        let temp_path = temp_dir.into_path();
        let temp_path = temp_path.join("some-file.txt");
        let temp_path_str = temp_path
            .to_str()
            .expect("Failed to convert temp path to str");

        let mut additional_replacements = HashMap::new();
        additional_replacements.insert(
            temp_path_str.to_string(),
            "/tmp/random-value/some-file.txt".to_string(),
        );

        let config = Config {
            tmux: Some(Tmux {
                sessions: vec![Session {
                    name: "foo".to_string(),
                    windows: vec![Window {
                        name: "bar".to_string(),
                        path: None,
                        command: Some(ConfigCommand::Single(format!("touch {}", temp_path_str))),
                    }],
                }],
            }),
        };

        let commands = startup_tmux(config, &options)?;

        let commands =
            sanitize_commands_executed(commands, &options, Some(additional_replacements));
        assert_yaml_snapshot!(commands, @r###"
        ---
        - "tmux -L [SOCKET_NAME] new-session -d -s foo -n bar"
        - "tmux -L [SOCKET_NAME] send-keys -t foo:bar touch /tmp/random-value/some-file.txt Enter"
        "###);
        assert_debug_snapshot!(gather_tmux_state(&options), @r###"
        {
            "foo": [
                "bar",
            ],
        }
        "###);

        wait_for_file(
            &temp_path,
            format!(
                "tmux socket: {} -- file not created: {}",
                options.socket_name,
                temp_path.to_str().unwrap()
            ),
        );

        Ok(())
    }
}
