#!/usr/bin/env bash
# install-nixos-ash.sh - Install the NixOS version of ash

# Colors
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
RED="\033[0;31m"
RESET="\033[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
NIXOS_ASH="$SCRIPT_DIR/nixos-ash"
INSTALL_DIR="$HOME/.local/bin"

echo -e "${BLUE}NixOS AI Shell Installer${RESET}"

# Check if the source file exists
if [[ ! -f "$NIXOS_ASH" ]]; then
    echo -e "${RED}Error: nixos-ash script not found at $NIXOS_ASH${RESET}"
    exit 1
fi

# Create installation directory if it doesn't exist
if [[ ! -d "$INSTALL_DIR" ]]; then
    echo -e "${YELLOW}Creating directory: $INSTALL_DIR${RESET}"
    mkdir -p "$INSTALL_DIR"
fi

# Install the NixOS version
echo -e "${YELLOW}Installing NixOS AI Shell to $INSTALL_DIR${RESET}"
cp "$NIXOS_ASH" "$INSTALL_DIR/nixos-ash"
chmod +x "$INSTALL_DIR/nixos-ash"

# Create an alias for the original ash command
echo -e "${YELLOW}Creating 'ash' alias script${RESET}"
cat > "$INSTALL_DIR/ash" << EOF
#!/usr/bin/env bash
# ash - Wrapper for nixos-ash
exec nixos-ash "\$@"
EOF
chmod +x "$INSTALL_DIR/ash"

echo -e "${GREEN}Installation complete!${RESET}"
echo -e "${YELLOW}To use immediately, run:${RESET}"
echo -e "export PATH=\"\$PATH:$INSTALL_DIR\""
echo -e "nixos-ash --trigger=magic"
echo
echo -e "${YELLOW}To make permanent, add this to your .bashrc:${RESET}"
echo -e "export PATH=\"\$PATH:$INSTALL_DIR\""
echo -e "alias ash='nixos-ash'" 