#!/bin/bash
# Installation script for GitHub workflow automation tools

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Installing GitHub Workflow Automation Tools${NC}"
echo ""

# Check if ~/bin exists, create if not
if [ ! -d "$HOME/bin" ]; then
    echo -e "${YELLOW}Creating ~/bin directory...${NC}"
    mkdir -p "$HOME/bin"
fi

# Copy scripts
echo "Copying scripts to ~/bin..."
cp bin/gh-create-repo-auto "$HOME/bin/"
cp bin/github-repo-auto-config.sh "$HOME/bin/"
chmod +x "$HOME/bin/gh-create-repo-auto"
chmod +x "$HOME/bin/github-repo-auto-config.sh"
echo -e "${GREEN}✓ Scripts installed${NC}"

# Install LaunchAgent
echo ""
echo "Installing LaunchAgent..."
cp launchd/com.github.repo-auto-config.plist "$HOME/Library/LaunchAgents/"

# Update username in plist
sed -i '' "s|/Users/jleechan|$HOME|g" "$HOME/Library/LaunchAgents/com.github.repo-auto-config.plist"

launchctl unload "$HOME/Library/LaunchAgents/com.github.repo-auto-config.plist" 2>/dev/null || true
launchctl load "$HOME/Library/LaunchAgents/com.github.repo-auto-config.plist"
echo -e "${GREEN}✓ LaunchAgent installed and started${NC}"

# Add alias to shell config
echo ""
echo "Adding alias to shell config..."
SHELL_CONFIG="$HOME/.zshrc"
if [ ! -f "$SHELL_CONFIG" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
fi

if ! grep -q "gh create-repo-auto" "$SHELL_CONFIG" 2>/dev/null; then
    echo "" >> "$SHELL_CONFIG"
    echo "# GitHub Workflow Automation alias" >> "$SHELL_CONFIG"
    echo 'alias gh-create="gh create-repo-auto"' >> "$SHELL_CONFIG"
    echo -e "${GREEN}✓ Alias added to $SHELL_CONFIG${NC}"
else
    echo -e "${YELLOW}⚠ Alias already exists in $SHELL_CONFIG${NC}"
fi

echo ""
echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo "Usage:"
echo "  gh-create-repo-auto jleechanorg/repo-name --public"
echo "  gh-create repo-name --public  (after sourcing shell config)"
echo ""
echo "To activate the alias now, run:"
echo "  source $SHELL_CONFIG"
