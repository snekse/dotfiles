#!/usr/bin/env bash
# SSH setup checkpoint — run between `just link` and `just install-runtimes`
# Do NOT add `set -e` here; we need to capture SSH exit codes explicitly.

KEY_ED25519="$HOME/.ssh/id_ed25519"
KEY_RSA="$HOME/.ssh/id_rsa"

# ── 1. Check for an existing key ────────────────────────────────────────────
if [[ -f "$KEY_ED25519" || -f "$KEY_RSA" ]]; then
  echo "==> SSH key found, skipping keygen."
else
  echo ""
  echo "==> No SSH key found."
  read -rp "    Generate a new ed25519 key? [Y/n] " gen
  gen="${gen:-Y}"

  if [[ "$gen" =~ ^[Yy]$ ]]; then
    read -rp "    Email for key comment (leave blank to skip): " email
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$email" -f "$KEY_ED25519"
    ssh-add "$KEY_ED25519"
  else
    echo ""
    echo "  WARNING: No SSH key generated."
    read -rp "  Continue anyway? Runtime installs may fail. [y/N] " cont
    cont="${cont:-N}"
    if [[ ! "$cont" =~ ^[Yy]$ ]]; then
      echo "  Aborting. Re-run install.sh once SSH is configured."
      exit 1
    fi
    echo "  Continuing without SSH key..."
    exit 0
  fi
fi

# ── 2. Print public key + instructions ──────────────────────────────────────
PUB_KEY=""
if [[ -f "${KEY_ED25519}.pub" ]]; then
  PUB_KEY="${KEY_ED25519}.pub"
elif [[ -f "${KEY_RSA}.pub" ]]; then
  PUB_KEY="${KEY_RSA}.pub"
fi

if [[ -n "$PUB_KEY" ]]; then
  echo ""
  echo "==> Your public key:"
  echo ""
  cat "$PUB_KEY"
  echo ""
  if command -v pbcopy &>/dev/null; then
    pbcopy < "$PUB_KEY"
    echo "  (Copied to clipboard)"
  fi
  echo "  Add it to GitHub: https://github.com/settings/ssh/new"
  echo ""
  read -rp "Press Enter once you have added the SSH key to GitHub..."
fi

# ── 3. Verify SSH connection with retry loop ─────────────────────────────────
while true; do
  echo "==> Verifying SSH connection to GitHub..."
  ssh_out=$(ssh -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1)
  ssh_exit=$?

  # GitHub exits 1 (not 0) on successful auth
  if [[ $ssh_exit -eq 1 ]] && echo "$ssh_out" | grep -q "successfully authenticated"; then
    echo "  SSH verified: $ssh_out"
    break
  else
    echo "  SSH verification failed (exit $ssh_exit): $ssh_out"
    echo ""
    read -rp "  [R]etry, [C]ontinue anyway, or [A]bort? [R/c/a] " choice
    choice="${choice:-R}"
    case "$choice" in
      [Cc])
        echo "  Continuing without verified SSH. Runtime installs may fail."
        break
        ;;
      [Aa])
        echo "  Aborting. Re-run install.sh once SSH is working."
        exit 1
        ;;
      *)
        # retry
        ;;
    esac
  fi
done
