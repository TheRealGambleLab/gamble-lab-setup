gl_setup: (pm-install "curl") (pm-install "7z" "p7zip") (pm-install "git") (pm-install "git-annex") (pm-install "rclone") (pm-install "git-annex-remote-rclone") install-uv (uv-tool-install "quarto" "quarto-cli") (uv-tool-install "gln" "git+ssh://git@github.com/TheRealGambleLab/gln#egg=gln[extensions]") install-gh install-typst

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

[macos, private]
install-pm:
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  which brew

[linux, private]
install-pm:
  which apt

[macos, private]
pm-update: install-pm
  brew update

[linux, private]
pm-update: install-pm
  sudo apt update

[macos, private, script("bash")]
pm-install app-name package-name="none": install-pm pm-update
  if command -v {{app-name}} >/dev/null 2>&1; then
    echo "{{app-name}} already installed"
    exit 0
  fi
  brew install {{ if package-name == "none" { app-name } else { package-name } }}

[linux, private, script("bash")]
pm-install app-name package-name="none": install-pm pm-update
  if command -v {{app-name}} >/dev/null 2>&1; then
    echo "{{app-name}} already installed"
    exit 0
  fi
  sudo apt install {{ if package-name == "none" { app-name } else { package-name } }}

[private, script("bash")]
install-uv: (pm-install "curl")
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

[macos, private]
install-gh: (pm-install "gh")

[linux, private]
install-gh:
  command -v gh >/dev/null 2>&1 || ( \
  (command -v wget >/dev/null 2>&1 || { sudo apt update && sudo apt-get install -y wget; }) \
  && sudo install -d -m 755 /etc/apt/keyrings \
  && tmp=$(mktemp) \
  && wget -qO "$tmp" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  && sudo install -m 644 "$tmp" /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] \
  https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null \
  && sudo apt-get update \
  && sudo apt-get install -y gh \
  )

[macos, private]
install-apptainer:
  echo "Apptainer not installed. For macOS follow these instructions. https://apptainer.org/docs/admin/main/installation.html#installation-on-windows-or-mac"

[linux, private]
install-apptainer:
  sudo apt install apptainer

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

