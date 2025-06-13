---
primary: Matthew Gamble
participants: [Matthew Gamble]
tags: [code, setup]
---

# Gamble Lab Setup

Run the one‑liner on **any** Mac, Linux workstation, WSL, or HPC login node:

    bash -c "$(curl -sSfL https://raw.githubusercontent.com/<ORG>/gamble-lab-setup/main/bootstrap.sh)"

If `curl` is unavailable, swap in `wget`:

    bash -c "$(wget -qO- https://raw.githubusercontent.com/<ORG>/gamble-lab-setup/main/bootstrap.sh)"

The script installs **uv**, **just**, downloads the correct Justfile for the host,
then executes it.  Further updates are as simple as re‑running the same command.
