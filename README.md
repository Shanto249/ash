# NixOS AI Shell (nixos-ash)

`nixos-ash` is an interactive command line shell, designed specifically for NixOS, that integrates with an AI command processor (like the `n` command for Ollama). It automatically routes unrecognized commands to the AI, providing a seamless way to use natural language for terminal tasks.

## Features

*   **Automatic AI Routing:** Unknown commands are sent to the configured AI command (`n` by default).
*   **Multiple AI Modes:**
    *   `auto` (default): Sends unknown commands *or* commands containing the trigger word to AI.
    *   `trigger`: Sends *only* commands containing the trigger word to AI.
    *   `all`: Sends *all* commands to AI.
*   **Customizable Trigger Word:** Define a keyword (default: `avarice`) to explicitly send commands to AI, even if the command exists.
*   **Clean Output Formatting:** Displays the AI-executed command clearly.
*   **NixOS Focused:** Uses a basic `read` loop to avoid common hanging issues found with more complex shells on NixOS.
*   **Configurable Prompt:** Change the shell prompt text.
*   **Verbose Mode:** Optional detailed output for debugging.

## Installation

1.  **Ensure `n` command is available:** This shell relies on an external AI command processor. Make sure the command configured in `nixos-ash` (default: `n`) is installed and accessible in your PATH.
2.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd nixos-ash # Or your repository directory name
    ```
3.  **Run the installer:**
    ```bash
    chmod +x install-nixos-ash.sh
    ./install-nixos-ash.sh
    ```
    This script will:
    *   Copy `nixos-ash` to `$HOME/.local/bin/`.
    *   Create a wrapper script `ash` in the same directory that simply calls `nixos-ash`.
    *   Make both scripts executable.

4.  **Update PATH:** Add `$HOME/.local/bin` to your PATH. You can do this temporarily:
    ```bash
    export PATH="$PATH:$HOME/.local/bin"
    ```
    Or permanently by adding the line above to your shell's configuration file (e.g., `~/.bashrc`, `~/.zshrc`).

## Usage

Once installed and your PATH is updated, simply type:

```bash
ash
```

This will launch the `nixos-ash` shell.

### Examples

```bash
# Assuming AI_MODE=auto (default)

ash$ ls -l # Executes normally
total 40
-rwxr-xr-x 1 user user 6435 May  2 10:00 nixos-ash
...

ash$ show me the time # Unknown command, goes to AI
avarice$ date         # AI decided to run 'date'
Wed May  2 10:01:00 PDT 2024

ash$ date avarice    # Contains trigger word, goes to AI
avarice$ date         # AI decided to run 'date'
Wed May  2 10:01:05 PDT 2024
```

### Command-Line Options

You can start `ash` (or `nixos-ash`) with options:

*   `--trigger=WORD`: Set a different trigger word for the session.
*   `--mode=MODE`: Set the AI mode (`auto`, `trigger`, `all`) for the session.
*   `--prompt=TEXT`: Set a custom prompt text.
*   `--verbose`: Enable detailed AI processing messages.
*   `--help`: Show help.
*   `--version`: Show version.

### Built-in Commands

*   `exit` or `quit`: Exit the shell.
*   `help`: Show available commands and current settings.
*   `version`: Display the shell version.
*   `get-trigger`: Show the current trigger word.
*   `set-mode [auto|trigger|all]`: Change the AI mode for the current session.
*   `set-prompt [TEXT]`: Change the prompt text for the current session.
*   `verbose`: Toggle verbose mode on/off.

## Making `ash` the Default Shell

The safest way to make `ash` launch automatically when you open a terminal is to add logic to your existing shell's startup file (e.g., `~/.bashrc`).

Add the following lines to the **top** of your `~/.bashrc` (or equivalent for other shells like `.zshrc`):

```bash
# Add nixos-ash to PATH if not already present
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$PATH:$HOME/.local/bin"
fi

# Automatically start ash (nixos-ash) for interactive shells
# Check if running interactively and if ASH_ACTIVE is not already set (to prevent loops)
if [[ $- == *i* ]] && [[ -z "$ASH_ACTIVE" ]]; then
    export ASH_ACTIVE=1 # Mark that we are inside ash
    # Check if nixos-ash exists before trying to execute
    if command -v nixos-ash &> /dev/null; then
        exec nixos-ash # Replace the current shell with nixos-ash
    else
        echo "Warning: nixos-ash command not found. Cannot launch AI Shell."
    fi
fi
```

**Important:**

*   Ensure these lines are **before** any other complex logic or sourcing of other files in your `.bashrc`.
*   Open a **new terminal** window to test the change. Do not just `source ~/.bashrc` in an existing window, as the `exec` command behaves differently.
*   To revert, simply remove or comment out these added lines from your `.bashrc`.

## Troubleshooting

*   **Hanging Shell:** This version uses a basic `read` loop specifically to avoid hanging issues common on NixOS. If it still hangs, there might be an issue with the underlying `bash` or terminal environment.
*   **Command Not Found:** Ensure `$HOME/.local/bin` is correctly added to your `PATH` *before* `ash` tries to launch.
*   **AI Command Not Working:** Verify that the command specified by `N_COMMAND` (default: `n`) is installed, executable, and in your `PATH`. `nixos-ash` includes a basic fallback if the command isn't found, but it won't have real AI capabilities.

## License

MIT 