#!/usr/bin/env bash
# gamble-lab-setup :: zero-to-just in one command
set -euo pipefail

# --------------------------- helpers ---------------------------------
log() { printf '\e[1;34m[setup]\e[0m %s\n' "$*"; }
err() { printf '\e[1;31m[error]\e[0m %s\n' "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

need_on_path() {
  case ":$PATH:" in
  *":$1:"*) return 0 ;; # already there
  *)
    printf 'export PATH="%s:$PATH"\n' "$1" >>"${HOME}/.bashrc"
    export PATH="$1:$PATH" # immediate effect
    ;;
  esac
}

download() {
  # $1 = URL   $2 = destination file
  if have curl; then
    curl -sSfL "$1" -o "$2"
  elif have wget; then
    wget -qO "$2" "$1"
  else
    err "curl or wget required"
    exit 1
  fi
}

is_hpc() {
  [[ "$HOME" == /gs/gsfs0/users/* ]]
}

# ---------------------------- uv -------------------------------------
if ! have uv; then
  log "uv not found – installing via official one-liner"
  if have curl; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
  elif have wget; then
    wget -qO- https://astral.sh/uv/install.sh | sh
  else
    err "Need curl or wget to install uv"
    exit 1
  fi

  # uv puts itself in ~/.local/bin on both macOS and Linux
  need_on_path "${HOME}/.local/bin"
else
  log "uv already present – skipping install"
fi

# --------------------------- just ------------------------------------
if ! have just; then
  log "installing rust-just via uv"
  uv tool install rust-just
else
  log "upgrading rust-just via uv (if newer exists)"
  uv tool upgrade rust-just || true # upgrade is a no-op if current
fi

# ------------------------- fetch justfile ----------------------------
cfg_root="${XDG_CONFIG_HOME:-$HOME/.config}/gamble-lab-setup"
mkdir -p "$cfg_root"

if is_hpc; then
  jf_url="https://raw.githubusercontent.com/TheRealGambleLab/gamble-lab-setup/refs/heads/master/gl-hpc-setup.just"
  jf_path="$cfg_root/gl-hpc-setup.just"
else
  jf_url="https://raw.githubusercontent.com/TheRealGambleLab/gamble-lab-setup/refs/heads/master/gl-setup.just"
  jf_path="$cfg_root/gl-setup.just"
fi

log "downloading $(basename "$jf_path")"
download "$jf_url" "$jf_path"

jf_url2="https://raw.githubusercontent.com/TheRealGambleLab/gamble-lab-setup/refs/heads/master/gl-git-config.just"
jf_path2="$cfg_root/gl-git-config.just"

download "$jf_url2" "$jf_path2"

jf_url3="https://raw.githubusercontent.com/TheRealGambleLab/gamble-lab-setup/refs/heads/master/gl-ssh-key.just"
jf_path3="$cfg_root/gl-ssh-key.just"

download "$jf_url3" "$jf_path3"

# --------------------------- run just --------------------------------
log "running bootstrap tasks from $(basename "$jf_path")"
exec just --justfile "$jf_path" "--dry-run" "$@" # pass any extra args from the user
