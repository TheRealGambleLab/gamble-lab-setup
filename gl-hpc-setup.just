set unstable

gl-setup: setup-conda (conda-install "curl") (conda-install "7z" "p7zip") (conda-install "git") (conda-install "git-annex") (conda-install "rclone") (conda-install "git-annex-remote-rclone") (conda-install "gh") (conda-install "apptainer") install-uv (uv-tool-install "quarto" "quarto-cli") (uv-tool-install "gln" "git+ssh://git@github.com/TheRealGambleLab/gln#egg=gln[extensions]") install-typst

[private, script("bash")]
ensure-local-bin-dir:
  mkdir -p "$HOME/.local/bin"
  LOCAL_BIN="$HOME/.local/bin"
  BASHRC="$HOME/.bashrc"
  EXPORT_LINE='export PATH="$HOME/.local/bin:$PATH"'
  if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    echo "➕ ~/.local/bin not in PATH"
    # Check if line is already in ~/.bashrc
    if ! grep -Fxq "$EXPORT_LINE" "$BASHRC"; then
      echo "$EXPORT_LINE" >> "$BASHRC"
      echo "✅ Added to ~/.bashrc: $EXPORT_LINE"
    else
      echo "ℹ️ Found export line already present in ~/.bashrc"
    fi
  else
    echo "✅ ~/.local/bin already in PATH"
  fi

[private, script("bash")]
conda-install app-name package-name="none": setup-conda
  if command -v {{app-name}} >/dev/null 2>&1; then
    echo "{{app-name}} already installed"
    exit 0
  fi
  conda install -c conda-forge -y -n gln-managed {{ if package-name == "none" { app-name } else { package-name } }}

[private, script("bash")]
install-conda:
  if command -v conda >/dev/null 2>&1; then
    exit 0
  fi
  mkdir ~/miniconda3/miniconda.sh
  wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
  bash ~/miniconda3/miniconda3.sh -b -u -p ~/miniconda3
  rm ~/miniconda3/miniconda.sh
  conda init

[private, script("bash")]
install-gln-managed-env: install-conda
  if conda env list | awk '{print $1}' | grep -Fxq gln-managed; then
    exit 0
  conda create -n gln-managed python=3.12

[private, script("uv", "run", "--script")]
setup-conda: install-conda install-gln-managed-env
  from pathlib import Path
  from subprocess import run
  import os
  import json
  env_path = [
    for e in json.loads(
      run(
        ["conda", "env", "list", "--json"],
        check=True,
        capture_output=True,
      ).stdout
    )["envs"]
    if Path(e).name == "gln-managed"
  ][0]
  bashrcFile = Path("~/.bashrc").expanduser()
  bashrcText = Path("~/.bashrc").expanduser().read_text()
  line = "export PATH=" + env_path + "/bin:$PATH"
  if line not in bashrcText.splitlines(keepends=True):
      bashrcText += "\n# >>> added by gln-setup\n" + line + "\n"
      bashrcFile.write_text(bashrcText)
    os.environ["PATH"] = f"{self.env_path}{os.pathsep}{os.environ['PATH']}"  # changes path now

[private, script("bash")]
install-uv: (conda-install "curl") ensure-local-bin-dir
  if command -v uv >/dev/null 2>&1; then
    echo "uv already installed."
    exit 0
  fi
  curl -LsSf https://astral.sh/uv/install.sh | sh

[private, script("bash")]
uv-tool-install app-name package-name="none" python="3.12": install-uv
  if command -v {{app-name}} >/dev/null 2>&1; then
    echo "{{app-name}} already installed."
    exit 0
  fi
  uv tool install --python {{python}} {{ if package-name == "none" { app-name } else { package-name } }}

[private, script("bash")]
install-typst:
  set -euo pipefail
  if command -v typst >/dev/null 2>&1; then
    echo "typst already installed."
    exit 0
  fi
  LOCAL_BIN="$HOME/.local/bin"
  TYPST_BIN="$LOCAL_BIN/typst"
  EXPORT_LINE='export PATH="$HOME/.local/bin:$PATH"'
  mkdir -p "$LOCAL_BIN"
  # Detect OS
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m)"
  # Normalize architecture
  case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="aarch64" ;;
    *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
  esac
  # Determine download URL
  if [[ "$OS" == "linux" ]]; then
    URL="https://github.com/typst/typst/releases/latest/download/typst-${ARCH}-unknown-linux-musl.tar.xz"
  elif [[ "$OS" == "darwin" ]]; then
    URL="https://github.com/typst/typst/releases/latest/download/typst-${ARCH}-apple-darwin.tar.xz"
  else
    echo "❌ Unsupported OS: $OS"
    exit 1
  fi
  echo "⬇️ Installing Typst for $ARCH-$OS..."
  # Download and install directly
  curl -Ls "$URL" | tar -xJf - -O > "$TYPST_BIN"
  chmod +x "$TYPST_BIN"
  echo "✅ Typst installed to $TYPST_BIN"

