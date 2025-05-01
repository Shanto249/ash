#!/usr/bin/env python3

import sys
import requests
import json
import subprocess
import os
import argparse
import configparser
from pathlib import Path
import textwrap

OLLAMA_API = "http://localhost:11434/api/generate"
MODEL = "llama3.2"  # Default model, can be changed
DEFAULT_CONFIG = {
    "model": MODEL,
    "require_confirmation": "yes",
    "api_endpoint": OLLAMA_API,
    "trigger_word": "",
    "trigger_word_enabled": "no"
}

def get_config_path():
    """Get the path to the config file"""
    config_dir = Path.home() / ".config" / "n-command"
    config_dir.mkdir(parents=True, exist_ok=True)
    return config_dir / "config.ini"

def load_config():
    """Load configuration from file or create default if it doesn't exist"""
    config = configparser.ConfigParser()
    config_path = get_config_path()
    
    if config_path.exists():
        config.read(config_path)
    
    if 'settings' not in config:
        config['settings'] = DEFAULT_CONFIG
        with open(config_path, 'w') as f:
            config.write(f)
    elif not all(key in config['settings'] for key in DEFAULT_CONFIG.keys()):
        # Add any missing keys that might be in newer versions
        for key, value in DEFAULT_CONFIG.items():
            if key not in config['settings']:
                config['settings'][key] = value
        with open(config_path, 'w') as f:
            config.write(f)
    
    return config

def save_config(config):
    """Save configuration to file"""
    config_path = get_config_path()
    with open(config_path, 'w') as f:
        config.write(f)

def generate_shell_integration(trigger_word):
    """Generate shell integration script content"""
    # Main shell integration approach
    content = f'''# n-command shell integration
# Add this to your .bashrc, .zshrc, or equivalent shell configuration file

# Function to intercept commands containing the trigger word
n_command_interceptor() {{
    # Get the command line
    cmd="$1"
    
    # Check if trigger word is present
    if [[ "$cmd" == *"{trigger_word}"* ]]; then
        # Extract the command part (everything after the trigger word)
        # First check if there's anything after the trigger word
        if [[ "$cmd" == *"{trigger_word} "* ]] || [[ "$cmd" == *"{trigger_word},"* ]]; then
            # There's content after the trigger word
            # Extract it using sed to get everything after the trigger word and any following space/comma
            command_part=$(echo "$cmd" | sed -E 's/.*{trigger_word}[, ]*//')
            
            # Check if command_part is empty
            if [[ -n "$command_part" ]]; then
                # Run the n command with the extracted part
                n $command_part
                # Return success to indicate command was handled
                return 0
            fi
        fi
        
        # If we get here, either the trigger word is at the end or there's no proper command after it
        echo "Usage: {trigger_word} <your command>"
        echo "Example: {trigger_word} list all files"
        # Return success to prevent original command from running
        return 0
    fi
    
    # Return false to indicate we should run the original command
    return 1
}}

# Shell-specific integration
if [[ -n "$BASH_VERSION" ]]; then
    # Remove any existing trap if present
    trap - DEBUG
    
    # Override the command execution with a preexec hook
    preexec_n_command() {{
        local cmd="$BASH_COMMAND"
        if n_command_interceptor "$cmd"; then
            # Command was intercepted, prevent original execution
            # We need to replace the current command with a harmless one
            BASH_COMMAND=":" # Noop command
        fi
    }}
    
    # Install the trap
    trap 'preexec_n_command' DEBUG

elif [[ -n "$ZSH_VERSION" ]]; then
    # Define the preexec hook for Zsh
    n_command_preexec() {{
        local cmd="$1"
        if n_command_interceptor "$cmd"; then
            # If intercepted, kill the current command line
            zle kill-whole-line
            zle reset-prompt
            return 0
        fi
    }}
    
    # Register the preexec hook
    autoload -U add-zsh-hook
    add-zsh-hook preexec n_command_preexec
fi

# IMPORTANT: Do NOT define a shell function with the trigger name
# This would cause command double execution
# The integration above will handle all trigger word detection

# For testing: this debug message will appear when the script is sourced
echo "n-command shell integration installed with trigger word: {trigger_word}"
'''
    
    return content

def write_shell_integration(trigger_word):
    """Write shell integration script to a file"""
    config_dir = Path.home() / ".config" / "n-command"
    integration_path = config_dir / "shell-integration.sh"
    
    with open(integration_path, 'w') as f:
        f.write(generate_shell_integration(trigger_word))
    
    print(f"\nShell integration file written to: {integration_path}")
    print(f"Add the following line to your shell config file (.bashrc, .zshrc, etc.):")
    print(f"\n    source {integration_path}\n")
    print("Then restart your shell or run 'source ~/.bashrc' (or equivalent).")
    
    # Create direct shell command
    bin_dir = Path.home() / ".local" / "bin"
    bin_dir.mkdir(parents=True, exist_ok=True)
    cmd_path = bin_dir / trigger_word
    
    with open(cmd_path, 'w') as f:
        f.write(f'''#!/bin/sh
# Direct command for n-command trigger word
exec n "$@"
''')
    
    # Make the file executable
    os.chmod(cmd_path, 0o755)
    
    print(f"\nDirect command created at: {cmd_path}")
    print(f"Make sure {bin_dir} is in your PATH to use the command directly.")
    print(f"Example usage: '{trigger_word} list all files'")
    
    # For NixOS users, suggest a systemd user service to add the bin directory to PATH
    if os.path.exists('/etc/nixos'):
        print("\nFor NixOS users: Consider adding the following to your configuration.nix:")
        print(f'''
environment.sessionVariables = {{
  PATH = [ "$HOME/.local/bin" ];
}};''')
        
    print("\nIMPORTANT: If you already had an older version of the shell integration,")
    print("you may need to remove your old .bashrc/.zshrc integration and restart your shell")
    print("to avoid command duplication issues.")

def get_available_models():
    """Get a list of available Ollama models"""
    try:
        response = requests.get(
            "http://localhost:11434/api/tags",
            timeout=5
        )
        response.raise_for_status()
        models = response.json().get("models", [])
        return [model["name"] for model in models]
    except:
        return []

def prompt_llm(query, model, api_endpoint):
    """
    Send a prompt to Ollama and get the shell command back
    """
    prompt = f"""You are a helpful assistant that turns natural language instructions into shell commands.
Return ONLY the shell command without any explanation, markdown formatting, or additional text.
For example, if the user says "create a new file called test.txt", you should return only "touch test.txt".

User request: {query}
Shell command:"""

    try:
        response = requests.post(
            api_endpoint,
            json={
                "model": model,
                "prompt": prompt,
                "stream": False,
            },
            timeout=30
        )
        response.raise_for_status()
        result = response.json()
        return result.get("response", "").strip()
    except requests.exceptions.RequestException as e:
        print(f"Error connecting to Ollama: {e}")
        print("Make sure Ollama is running with 'ollama serve'")
        sys.exit(1)

def execute_command(command, require_confirmation=True):
    """
    Execute the generated shell command
    """
    print(f"Executing: {command}")
    
    # Ask for confirmation before running the command if required
    if require_confirmation:
        confirm = input("Run this command? [y/N]: ").lower()
        if confirm != 'y':
            print("Command execution cancelled.")
            return

    try:
        result = subprocess.run(command, shell=True, text=True)
        return result.returncode
    except Exception as e:
        print(f"Error executing command: {e}")
        return 1

def display_menu():
    """Display the configuration menu"""
    config = load_config()
    settings = config['settings']
    
    while True:
        os.system('clear' if os.name != 'nt' else 'cls')
        print(textwrap.dedent("""
        ╭────────────────────────────────╮
        │      n-command Settings        │
        ╰────────────────────────────────╯
        """))
        
        print(f"  1. Ollama Model:           {settings.get('model')}")
        print(f"  2. Require Confirmation:   {settings.get('require_confirmation')}")
        print(f"  3. API Endpoint:           {settings.get('api_endpoint')}")
        print(f"  4. Trigger Word:           {settings.get('trigger_word') or '(not set)'}")
        print(f"  5. Trigger Word Enabled:   {settings.get('trigger_word_enabled')}")
        print(f"  6. Generate Shell Integration")
        print(f"  7. Test Connection")
        print(f"  8. Save and Exit")
        print(f"  9. Exit Without Saving")
        
        choice = input("\nEnter your choice (1-9): ")
        
        if choice == '1':
            # Get available models
            print("\nFetching available models...")
            models = get_available_models()
            
            if models:
                print("\nAvailable models:")
                for i, model in enumerate(models, 1):
                    print(f"  {i}. {model}")
                
                model_choice = input("\nSelect a model number (or enter a custom model name): ")
                
                try:
                    model_index = int(model_choice) - 1
                    if 0 <= model_index < len(models):
                        settings['model'] = models[model_index]
                    else:
                        print("Invalid model number.")
                except ValueError:
                    # User entered a custom model name
                    settings['model'] = model_choice
            else:
                model_name = input("\nCould not fetch models. Enter model name manually: ")
                settings['model'] = model_name
        
        elif choice == '2':
            confirm = input("\nRequire confirmation before executing commands? (yes/no): ").lower()
            if confirm in ('yes', 'no'):
                settings['require_confirmation'] = confirm
        
        elif choice == '3':
            api = input(f"\nEnter API endpoint (current: {settings.get('api_endpoint')}): ")
            if api:
                settings['api_endpoint'] = api
        
        elif choice == '4':
            trigger = input("\nEnter trigger word (e.g., 'avarice', 'jarvis'): ")
            if trigger:
                settings['trigger_word'] = trigger
                print(f"\nTrigger word set to '{trigger}'.")
                print("Now when you say something like 'hey {trigger}, list files', the command will be triggered.")
                print("Remember to enable the trigger word and generate shell integration.")
        
        elif choice == '5':
            enable = input("\nEnable trigger word? (yes/no): ").lower()
            if enable in ('yes', 'no'):
                settings['trigger_word_enabled'] = enable
                
                if enable == 'yes' and not settings.get('trigger_word'):
                    print("\nWarning: Trigger word is not set. Please set a trigger word first.")
        
        elif choice == '6':
            trigger_word = settings.get('trigger_word', '')
            if not trigger_word:
                print("\nError: Trigger word is not set. Please set a trigger word first.")
            else:
                write_shell_integration(trigger_word)
                input("\nPress Enter to continue...")
                
        elif choice == '7':
            print("\nTesting connection to Ollama...")
            try:
                response = requests.get(
                    "http://localhost:11434/api/tags",
                    timeout=5
                )
                if response.status_code == 200:
                    print("✓ Connection successful!")
                    
                    # Check if selected model exists
                    models = [model["name"] for model in response.json().get("models", [])]
                    model_name = settings.get('model')
                    
                    if model_name in models:
                        print(f"✓ Model '{model_name}' is available.")
                    else:
                        print(f"⚠ Warning: Model '{model_name}' was not found in available models.")
                        print(f"  Available models: {', '.join(models)}")
                else:
                    print(f"✗ Connection error: Status code {response.status_code}")
            except requests.exceptions.RequestException as e:
                print(f"✗ Connection error: {e}")
            
            input("\nPress Enter to continue...")
        
        elif choice == '8':
            save_config(config)
            print("\nSettings saved successfully!")
            break
        
        elif choice == '9':
            print("\nExiting without saving...")
            break
        
        else:
            print("\nInvalid choice. Please try again.")
            input("\nPress Enter to continue...")

def main():
    parser = argparse.ArgumentParser(description='Convert natural language to shell commands using Ollama')
    parser.add_argument('query', nargs='*', help='Natural language command description (quotes optional)')
    parser.add_argument('--config', '-c', action='store_true', help='Open configuration menu')
    parser.add_argument('--install-shell-integration', action='store_true', help='Generate and install shell integration')
    args = parser.parse_args()
    
    # Load configuration
    config = load_config()
    settings = config['settings']
    
    # Override settings with environment variables if set
    model = os.environ.get("N_OLLAMA_MODEL") or settings.get('model')
    api_endpoint = os.environ.get("N_OLLAMA_API") or settings.get('api_endpoint')
    require_confirmation = settings.get('require_confirmation', 'yes').lower() == 'yes'
    
    # Install shell integration if requested
    if args.install_shell_integration:
        trigger_word = settings.get('trigger_word', '')
        if not trigger_word:
            print("Error: Trigger word is not set. Please set a trigger word with 'n --config' first.")
            sys.exit(1)
        write_shell_integration(trigger_word)
        return
    
    # Open config menu if requested
    if args.config:
        display_menu()
        return
    
    # Handle the command
    if not args.query:
        print("Usage: n your natural language command (quotes optional)")
        print("Example: n list all python files")
        print("   or   n --config to open settings")
        sys.exit(1)
    
    # Join all arguments to form the query
    query = " ".join(args.query)
    
    # Get command from LLM
    command = prompt_llm(query, model, api_endpoint)
    
    if not command:
        print("Failed to generate a valid command.")
        sys.exit(1)
    
    # Execute the command
    return_code = execute_command(command, require_confirmation)
    sys.exit(return_code)

if __name__ == "__main__":
    main() 