#!/usr/bin/env bash
# GPG key generation and setup
# Collects name, email, passphrase; generates a key; offers exports and keyserver publish

set -e

echo ""
echo "==> GPG Key Setup"
echo ""
echo "This script will generate a new GPG key for commit signing."
echo ""

# ── 1. Collect user input ──────────────────────────────────────────────────────

read -rp "Real name [default: Derek Eskens]: " key_name
key_name="${key_name:-Derek Eskens}"

read -rp "Email (must match GitHub or your signing email): " key_email
[[ -z "$key_email" ]] && { echo "Email cannot be empty. Aborting."; exit 1; }

echo ""
echo "Passphrase (not shown as you type):"
read -rsp "Passphrase: " passphrase
echo ""
read -rsp "Confirm passphrase: " passphrase_confirm
echo ""

if [[ "$passphrase" != "$passphrase_confirm" ]]; then
  echo "ERROR: Passphrases do not match. Aborting."
  exit 1
fi

# ── 2. Warn about passphrase ───────────────────────────────────────────────────

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    ⚠️  IMPORTANT  ⚠️                           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Your GPG passphrase CANNOT BE RECOVERED if lost."
echo ""
echo "Save it immediately to your password manager or vault:"
echo "  - Passphrase will be used locally when signing commits"
echo "  - If you use GitHub Actions to publish artifacts, save it as"
echo "    'GPG_SIGNING_PASSWORD' repository secret"
echo ""
read -rp "Ready to generate the key? [y/N] " ready
ready="${ready:-N}"
[[ "$ready" =~ ^[Yy]$ ]] || { echo "Aborting."; exit 1; }

# ── 3. Generate key via batch mode ─────────────────────────────────────────────

echo ""
echo "==> Generating GPG key (this may take a moment)..."
echo ""

tmpfile=$(mktemp)
trap "rm -f $tmpfile" EXIT

cat > "$tmpfile" << EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $key_name
Name-Email: $key_email
Expire-Date: 0
Passphrase: $passphrase
%commit
EOF

chmod 600 "$tmpfile"
gpg --batch --gen-key "$tmpfile"

# ── 4. List secret keys and extract Key ID ─────────────────────────────────────

echo ""
echo "==> Your GPG secret keys:"
echo ""

# Get the full output and save for parsing
keys_output=$(gpg --list-secret-keys --keyid-format=long 2>/dev/null || true)
echo "$keys_output"

# Parse Key ID from the sec line (format: "sec rsa4096/AABBCCDD11223344")
key_id=$(echo "$keys_output" | grep "^sec" | awk '{print $2}' | cut -d'/' -f2 | head -1)

if [[ -z "$key_id" ]]; then
  echo "WARNING: Could not parse Key ID from gpg output. You can find it manually:"
  echo "  gpg --list-secret-keys --keyid-format=long"
  echo "  Look for the line starting with 'sec' and use the value after the '/'"
  exit 1
fi

echo ""
echo "✓ Your Key ID: $key_id"
echo ""
echo "Save this Key ID to your vault."
echo ""

# ── 5. Offer to publish key to keyserver ──────────────────────────────────────

read -rp "Publish public key to keys.openpgp.org? [y/N] " publish
if [[ "${publish:-N}" =~ ^[Yy]$ ]]; then
  echo ""
  echo "==> Publishing key to keys.openpgp.org..."
  gpg --keyserver keys.openpgp.org --send-keys "$key_id"
  echo "✓ Key published."
fi

# ── 6. Offer to export public key ──────────────────────────────────────────────

read -rp "Export public key now? (for adding to GitHub) [Y/n] " export_pub
if [[ "${export_pub:-Y}" =~ ^[Yy]$ ]]; then
  echo ""
  echo "==> Exporting public key..."
  pub_key=$(gpg --armor --export "$key_id")

  read -rp "Output to (c)lipboard or (d)isplay? [c/d, default: d] " dest
  if [[ "${dest:-d}" =~ ^[Cc]$ ]]; then
    echo "$pub_key" | pbcopy
    echo "✓ Public key copied to clipboard."
  else
    echo ""
    echo "$pub_key"
    echo ""
    echo "✓ Public key displayed above."
  fi

  echo ""
  echo "Add this key to GitHub:"
  echo "  1. Go to https://github.com/settings/keys"
  echo "  2. Click 'New GPG key'"
  echo "  3. Paste the key and click 'Add GPG key'"
  echo ""
fi

# ── 7. Offer to export private key ─────────────────────────────────────────────

read -rp "Export private key? (for GitHub Actions CI/CD workflows) [y/N] " export_priv
if [[ "${export_priv:-N}" =~ ^[Yy]$ ]]; then
  echo ""
  echo "==> Exporting private key..."
  priv_key=$(gpg --armor --export-secret-keys "$key_id")

  read -rp "Output to (c)lipboard or (d)isplay? [c/d, default: d] " dest
  if [[ "${dest:-d}" =~ ^[Cc]$ ]]; then
    echo "$priv_key" | pbcopy
    echo "✓ Private key copied to clipboard."
  else
    echo ""
    echo "$priv_key"
    echo ""
    echo "✓ Private key displayed above."
  fi

  echo ""
  echo "Add this key to GitHub Actions as a repository secret:"
  echo "  1. Go to your repo on GitHub → Settings → Secrets and variables → Actions"
  echo "  2. Click 'New repository secret'"
  echo "  3. Name: 'GPG_SIGNING_KEY'"
  echo "  4. Paste the private key (the full armored block)"
  echo ""
  echo "Also add the passphrase as another secret:"
  echo "  1. Click 'New repository secret' again"
  echo "  2. Name: 'GPG_SIGNING_PASSWORD'"
  echo "  3. Paste: <your passphrase>"
  echo ""
fi

# ── 8. Final summary ───────────────────────────────────────────────────────────

echo ""
echo "==> Setup complete!"
echo ""
echo "Summary:"
echo "  Key ID: $key_id"
echo "  Name: $key_name"
echo "  Email: $key_email"
echo ""
echo "Next steps:"
echo "  1. Save your passphrase to your password manager (if not already done)"
echo "  2. If not already done, add the public key to GitHub"
echo "  3. Run 'just setup-git-personal' to configure git commit signing"
echo ""
