# Moonshine Edition

A standalone, isolated edition of opencode that runs `qwen3.5:0.8b` locally via Ollama under the model id `moonshine`. It installs to its own directory and uses isolated config/data so it does not interfere with a regular `opencode` installation.

## Install

### macOS / Linux

```sh
curl -fsSL https://raw.githubusercontent.com/GenLabsAI/opencode/dev/moonshine/install.sh | bash
```

### Windows (PowerShell)

```powershell
iwr -useb https://raw.githubusercontent.com/GenLabsAI/opencode/dev/moonshine/install.ps1 | iex
```

## Uninstall

### macOS / Linux

```sh
curl -fsSL https://raw.githubusercontent.com/GenLabsAI/opencode/dev/moonshine/uninstall.sh | bash
```

### Windows (PowerShell)

```powershell
iwr -useb https://raw.githubusercontent.com/GenLabsAI/opencode/dev/moonshine/uninstall.ps1 | iex
```

## How it works

- Installs to `~/.moonshine/bin` (`%USERPROFILE%\.moonshine\bin` on Windows).
- A `moonshine` launcher wrapper sets `OPENCODE_CONFIG_DIR` and the `XDG_*` directories to point inside `~/.moonshine`, so it never reads or writes the regular opencode config/data.
- Downloads release artifacts from `GenLabsAI/opencode` GitHub Releases.
- Uninstalling just deletes `~/.moonshine` and removes the PATH entry on Windows.
