#!/usr/bin/env bash
set -euo pipefail

echo "Uninstalling Moonshine Edition..."

# Remove binaries and data directory
rm -rf "$HOME/.moonshine"

echo "Removed ~/.moonshine."
echo "Note: PATH modifications in your shell profiles (e.g. .bashrc, .zshrc) have not been automatically removed."
echo "You may want to manually remove the $HOME/.moonshine/bin entry from your PATH."
