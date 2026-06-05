#!/usr/bin/env bash
set -euo pipefail
APP=moonshine

MUTED='\033[0;2m'
RED='\033[0;31m'
ORANGE='\033[38;5;214m'
NC='\033[0m'

usage() {
    cat <<EOF
Moonshine Edition Installer

Usage: install.sh [options]

Options:
    -h, --help              Display this help message
    -v, --version <version> Install a specific version
        --no-modify-path    Don't modify shell config files
EOF
}

requested_version=${VERSION:-}
no_modify_path=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        -v|--version) requested_version="$2"; shift 2 ;;
        --no-modify-path) no_modify_path=true; shift ;;
        *) echo -e "${ORANGE}Warning: Unknown option '$1'${NC}" >&2; shift ;;
    esac
done

INSTALL_DIR=$HOME/.moonshine/bin
mkdir -p "$INSTALL_DIR"

raw_os=$(uname -s)
os=$(echo "$raw_os" | tr '[:upper:]' '[:lower:]')
case "$raw_os" in
  Darwin*) os="darwin" ;;
  Linux*) os="linux" ;;
  MINGW*|MSYS*|CYGWIN*) os="windows" ;;
esac

arch=$(uname -m)
if [[ "$arch" == "aarch64" ]]; then arch="arm64"; fi
if [[ "$arch" == "x86_64" ]]; then arch="x64"; fi

if [ "$os" = "darwin" ] && [ "$arch" = "x64" ]; then
  rosetta_flag=$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)
  if [ "$rosetta_flag" = "1" ]; then arch="arm64"; fi
fi

combo="$os-$arch"
case "$combo" in
  linux-x64|linux-arm64|darwin-x64|darwin-arm64|windows-x64)
    ;;
  *)
    echo -e "${RED}Unsupported OS/Arch: $os/$arch${NC}"
    exit 1
    ;;
esac

archive_ext=".zip"
if [ "$os" = "linux" ]; then archive_ext=".tar.gz"; fi

target="$os-$arch"
filename="opencode-$target$archive_ext"

if [ -z "$requested_version" ]; then
    url="https://github.com/GenLabsAI/opencode/releases/latest/download/$filename"
else
    requested_version="${requested_version#v}"
    url="https://github.com/GenLabsAI/opencode/releases/download/v${requested_version}/$filename"
fi

echo -e "${MUTED}Downloading Moonshine Edition from: ${NC}$url"
tmp_dir="${TMPDIR:-/tmp}/moonshine_install_$$"
mkdir -p "$tmp_dir"

if ! curl -# -L -f -o "$tmp_dir/$filename" "$url"; then
    echo -e "${RED}Download failed. Check the version or URL.${NC}"
    exit 1
fi

echo -e "${MUTED}Extracting...${NC}"
if [ "$os" = "linux" ]; then
    tar -xzf "$tmp_dir/$filename" -C "$tmp_dir"
else
    unzip -q "$tmp_dir/$filename" -d "$tmp_dir"
fi

# Create launcher script
cat > "$INSTALL_DIR/moonshine" << 'EOF'
#!/usr/bin/env bash

# Isolate configuration and data
export OPENCODE_CONFIG_DIR="$HOME/.moonshine/config"
export XDG_DATA_HOME="$HOME/.moonshine/data"
export XDG_STATE_HOME="$HOME/.moonshine/state"
export XDG_CACHE_HOME="$HOME/.moonshine/cache"
export XDG_CONFIG_HOME="$HOME/.moonshine/config"

# Pass through all arguments to the binary
exec "$HOME/.moonshine/bin/opencode" "$@"
EOF

mv "$tmp_dir/opencode" "$INSTALL_DIR/opencode"
chmod 755 "$INSTALL_DIR/opencode" "$INSTALL_DIR/moonshine"
rm -rf "$tmp_dir"

echo -e "\n${MUTED}Successfully installed Moonshine Edition to ${NC}$INSTALL_DIR"

add_to_path() {
    local config_file=$1
    local command=$2
    if grep -Fxq "$command" "$config_file" 2>/dev/null; then
        return
    elif [[ -w $config_file ]]; then
        echo -e "\n# moonshine" >> "$config_file"
        echo "$command" >> "$config_file"
        echo -e "${MUTED}Added to PATH in ${NC}$config_file"
    fi
}

if [[ "$no_modify_path" != "true" ]]; then
    current_shell=$(basename "$SHELL")
    case $current_shell in
        fish)
            add_to_path "$HOME/.config/fish/config.fish" "fish_add_path $INSTALL_DIR"
        ;;
        zsh)
            for f in "${ZDOTDIR:-$HOME}/.zshrc" "${ZDOTDIR:-$HOME}/.zshenv"; do
                [[ -f $f ]] && add_to_path "$f" "export PATH=\"$INSTALL_DIR:\$PATH\"" && break
            done
        ;;
        bash|ash|sh|*)
            for f in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
                [[ -f $f ]] && add_to_path "$f" "export PATH=\"$INSTALL_DIR:\$PATH\"" && break
            done
        ;;
    esac
fi

echo -e "\nRun '${ORANGE}moonshine${NC}' to start."
