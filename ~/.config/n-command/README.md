# N Command Shell Integration

This directory contains shell integration scripts for the "n" command. These integrations allow you to use the trigger word "avarice" in various ways to invoke the AI-powered command generator.

## Usage Options

You can now use the command in several different ways:

1. **Direct command**:
   ```
   avarice list all files in my documents folder
   ```

2. **Using helper commands** (easiest approach, recommended):
   ```
   hey avarice list files
   please avarice show me documents  
   show me avarice in action
   ```
   These helper commands make it much easier to use natural language with the trigger word, and work reliably in all shells.

3. **Trigger word anywhere** (requires shell integration):
   ```
   please list all files in my documents folder with avarice
   ```
   *Note: This approach works best when combined with helper commands and has some limitations in complex commands.*

When any of these command patterns are detected, the **entire command line** is passed to the n command. This allows for maximum flexibility in how you phrase your requests.

## Installation

The integration is installed automatically by running:

```
~/.config/n-command/install-integration.sh
```

This adds the appropriate sourcing commands to your shell configuration files.

## How It Works

The integration uses multiple mechanisms to intercept commands:

1. **Helper commands** (`hey`, `please`, `show`): 
   - These are shell functions that check their arguments for the trigger word
   - If the trigger word is found, they pass the entire command to n
   - If not, they pass through to the real command if it exists

2. **Advanced interception** (works differently in each shell):
   - **Bash/Zsh**: Uses readline binding and DEBUG trap 
   - **Fish**: Uses fish_preexec and fish_command_not_found events

When a command containing the trigger word is detected, the integration:
1. Prevents the original command from executing
2. Passes the entire original command to the n command
3. Displays helpful feedback about what's happening

## Customization

To modify the trigger word, edit the following configuration files:

- Bash/Zsh: `~/.config/n-command/shell-integration.sh`
- Fish: `~/.config/n-command/fish-integration.fish`

Change the `TRIGGER_WORD` variable at the top of the file to your preferred trigger word.

You can also add more helper command functions to suit your personal style.

## Troubleshooting

If the integration doesn't work:

1. Try using the helper commands (hey, please, show) with the trigger word, as they're the most reliable
2. Make sure the integration script is being sourced in your shell configuration
3. Try restarting your shell or explicitly sourcing the integration file
4. Check for error messages with DEBUG_MODE=true in the integration scripts

## Manual Usage

If the automatic integration isn't working, you can always use the direct command form:

```
n list all files in my documents folder
```

Or the wrapper command:

```
avarice list all files in my documents folder
``` 