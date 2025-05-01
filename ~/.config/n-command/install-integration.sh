#!/bin/bash
# n-command shell integration installer
# This script helps users properly set up shell integration for the n command

CONFIG_DIR="$HOME/.config/n-command"
BASH_INTEGRATION="$CONFIG_DIR/shell-integration.sh"
FISH_INTEGRATION="$CONFIG_DIR/fish-integration.fish"
ZSH_INTEGRATION="$CONFIG_DIR/zsh-integration.sh"
TRIGGER_WORD="avarice"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Function to detect shells installed on the system
detect_shells() {
    local shells=()
    
    # Check for bash
    if command -v bash &>/dev/null; then
        shells+=("bash")
    fi
    
    # Check for fish
    if command -v fish &>/dev/null; then
        shells+=("fish")
    fi
    
    # Check for zsh
    if command -v zsh &>/dev/null; then
        shells+=("zsh")
    fi
    
    echo "${shells[@]}"
}

# Function to install bash integration
install_bash_integration() {
    echo "Installing Bash integration..."
    
    # Check if bash is installed
    if ! command -v bash &>/dev/null; then
        echo "Bash not found on this system."
        return 1
    fi
    
    # Check if .bashrc exists
    if [ ! -f "$HOME/.bashrc" ]; then
        echo "Creating ~/.bashrc file..."
        touch "$HOME/.bashrc"
    fi
    
    # Check if integration is already in .bashrc
    if grep -q "source.*$BASH_INTEGRATION" "$HOME/.bashrc"; then
        echo "Bash integration already installed."
    else
        echo "Adding integration to ~/.bashrc..."
        echo "" >> "$HOME/.bashrc"
        echo "# n-command integration" >> "$HOME/.bashrc"
        echo "if [ -f \"$BASH_INTEGRATION\" ]; then" >> "$HOME/.bashrc"
        echo "    source \"$BASH_INTEGRATION\"" >> "$HOME/.bashrc"
        echo "fi" >> "$HOME/.bashrc"
        echo "Bash integration installed successfully."
    fi
    
    echo "To use the integration in your current session, run:"
    echo "  source $BASH_INTEGRATION"
}

# Function to install fish integration
install_fish_integration() {
    echo "Installing Fish integration..."
    
    # Check if fish is installed
    if ! command -v fish &>/dev/null; then
        echo "Fish not found on this system."
        return 1
    fi
    
    # Create fish config directory if needed
    FISH_CONFIG_DIR="$HOME/.config/fish"
    FISH_CONFIG_FILE="$FISH_CONFIG_DIR/config.fish"
    
    mkdir -p "$FISH_CONFIG_DIR"
    
    # Create config.fish if it doesn't exist
    if [ ! -f "$FISH_CONFIG_FILE" ]; then
        echo "Creating fish config file..."
        touch "$FISH_CONFIG_FILE"
    fi
    
    # Check if integration is already in config.fish
    if grep -q "source.*$FISH_INTEGRATION" "$FISH_CONFIG_FILE"; then
        echo "Fish integration already installed."
    else
        echo "Adding integration to fish config..."
        echo "" >> "$FISH_CONFIG_FILE"
        echo "# n-command integration" >> "$FISH_CONFIG_FILE"
        echo "if test -f \"$FISH_INTEGRATION\"" >> "$FISH_CONFIG_FILE"
        echo "    source \"$FISH_INTEGRATION\"" >> "$FISH_CONFIG_FILE"
        echo "end" >> "$FISH_CONFIG_FILE"
        echo "Fish integration installed successfully."
    fi
    
    echo "To use the integration in your current session, run:"
    echo "  source $FISH_INTEGRATION"
}

# Function to install zsh integration
install_zsh_integration() {
    echo "Installing Zsh integration..."
    
    # Check if zsh is installed
    if ! command -v zsh &>/dev/null; then
        echo "Zsh not found on this system."
        return 1
    fi
    
    # Check if .zshrc exists
    if [ ! -f "$HOME/.zshrc" ]; then
        echo "Creating ~/.zshrc file..."
        touch "$HOME/.zshrc"
    fi
    
    # For zsh, we'll just use the bash integration since they're compatible
    cp "$BASH_INTEGRATION" "$ZSH_INTEGRATION"
    
    # Check if integration is already in .zshrc
    if grep -q "source.*$ZSH_INTEGRATION" "$HOME/.zshrc"; then
        echo "Zsh integration already installed."
    else
        echo "Adding integration to ~/.zshrc..."
        echo "" >> "$HOME/.zshrc"
        echo "# n-command integration" >> "$HOME/.zshrc"
        echo "if [ -f \"$ZSH_INTEGRATION\" ]; then" >> "$HOME/.zshrc"
        echo "    source \"$ZSH_INTEGRATION\"" >> "$HOME/.zshrc"
        echo "fi" >> "$HOME/.zshrc"
        echo "Zsh integration installed successfully."
    fi
    
    echo "To use the integration in your current session, run:"
    echo "  source $ZSH_INTEGRATION"
}

# Main installation logic
echo "=== n-command Shell Integration Installer ==="
echo "This script will install shell integration for using the trigger word '$TRIGGER_WORD'"
echo "in your commands to invoke the n command."

# Detect installed shells
INSTALLED_SHELLS=($(detect_shells))

if [ ${#INSTALLED_SHELLS[@]} -eq 0 ]; then
    echo "No supported shells detected on this system."
    exit 1
fi

echo "Detected shells: ${INSTALLED_SHELLS[*]}"
echo ""

# Install for each detected shell
for shell in "${INSTALLED_SHELLS[@]}"; do
    case "$shell" in
        bash)
            install_bash_integration
            ;;
        fish)
            install_fish_integration
            ;;
        zsh)
            install_zsh_integration
            ;;
    esac
    echo ""
done

echo "=== Installation Complete ==="
echo "Shell integration has been installed for: ${INSTALLED_SHELLS[*]}"
echo ""
echo "To use the integration, restart your shell or source the appropriate file."
echo "You can now use the following command patterns:"
echo "  1. $TRIGGER_WORD list files             (direct command)"
echo "  2. hey $TRIGGER_WORD, list files        (trigger in sentence)"
echo "  3. show me files $TRIGGER_WORD please   (trigger anywhere)"
echo ""
echo "To modify the trigger word, edit the configuration files in:"
echo "  $CONFIG_DIR" 