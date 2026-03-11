#!/usr/bin/env bash
# Interactively build or update ~/.ssh/config.
# Do NOT add `set -e` — interactive prompts and conflict resolution need
# fine-grained control flow.

SSH_CONFIG="$HOME/.ssh/config"
SSH_CONFIG_BAK="$HOME/.ssh/config.bak"

# ── Parsed state ──────────────────────────────────────────────────────────────
global_section=""        # lines before the first Host block
declare -a block_names=()
declare -a block_types=()  # "active" | "commented"
declare -a block_texts=()  # full raw text of each block

# ── New blocks to add ─────────────────────────────────────────────────────────
declare -a new_names=()
declare -a new_texts=()

# ── Parsing ───────────────────────────────────────────────────────────────────
parse_config() {
  local file="$1"
  local state="global"
  local current_name=""
  local current_text=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^Host[[:space:]]+(.+)$ ]]; then
      # Flush previous block
      if [[ "$state" != "global" ]]; then
        block_names+=("$current_name")
        block_types+=("$state")
        block_texts+=("$current_text")
      fi
      current_name="${BASH_REMATCH[1]}"
      current_text="$line"$'\n'
      state="active"

    elif [[ "$state" != "active" ]] && [[ "$line" =~ ^[[:space:]]*#[[:space:]]*Host[[:space:]]+(.+)$ ]]; then
      # Commented Host block — only recognized outside of an active block
      # (a "# Host" line inside an active block is just a comment)
      if [[ "$state" == "commented" ]]; then
        block_names+=("$current_name")
        block_types+=("$state")
        block_texts+=("$current_text")
      fi
      current_name="${BASH_REMATCH[1]}"
      current_text="$line"$'\n'
      state="commented"

    else
      if [[ "$state" == "global" ]]; then
        global_section+="$line"$'\n'
      else
        current_text+="$line"$'\n'
      fi
    fi
  done < "$file"

  # Flush final block
  if [[ "$state" != "global" && -n "$current_text" ]]; then
    block_names+=("$current_name")
    block_types+=("$state")
    block_texts+=("$current_text")
  fi
}

# ── Commented block triage ────────────────────────────────────────────────────
triage_commented_blocks() {
  local any_commented=false
  for type in "${block_types[@]}"; do
    [[ "$type" == "commented" ]] && any_commented=true && break
  done
  $any_commented || return 0

  echo ""
  echo "==> Found commented-out Host blocks in your existing config."
  echo "    Review each one and choose to retain or delete it."

  local -a kept_names=() kept_types=() kept_texts=()

  for i in "${!block_names[@]}"; do
    if [[ "${block_types[$i]}" == "commented" ]]; then
      echo ""
      echo "  ── Commented block: ${block_names[$i]} ──────────────────────────"
      echo "${block_texts[$i]}"
      read -rp "  [R]etain / [D]elete (default: R): " choice
      choice="${choice:-R}"
      if [[ "$choice" =~ ^[Dd]$ ]]; then
        echo "  Deleted."
        continue
      else
        echo "  Retained."
      fi
    fi
    kept_names+=("${block_names[$i]}")
    kept_types+=("${block_types[$i]}")
    kept_texts+=("${block_texts[$i]}")
  done

  block_names=("${kept_names[@]+"${kept_names[@]}"}")
  block_types=("${kept_types[@]+"${kept_types[@]}"}")
  block_texts=("${kept_texts[@]+"${kept_texts[@]}"}")
}

# ── Block builders ────────────────────────────────────────────────────────────
add_github_block() {
  read -rp "  IdentityFile [~/.ssh/id_ed25519_github]: " id_file
  id_file="${id_file:-~/.ssh/id_ed25519_github}"
  new_names+=("github.com")
  new_texts+=("Host github.com
  HostName github.com
  User git
  IdentityFile $id_file
  AddKeysToAgent yes
  UseKeychain yes
")
}

add_generic_block() {
  read -rp "  Host alias (e.g. myserver): " alias
  [[ -z "$alias" ]] && echo "  Alias cannot be empty. Skipping." && return
  read -rp "  HostName (IP or FQDN): " hostname
  read -rp "  User: " user
  read -rp "  IdentityFile path: " id_file
  new_names+=("$alias")
  new_texts+=("Host $alias
  HostName $hostname
  User $user
  IdentityFile $id_file
  AddKeysToAgent yes
  UseKeychain yes
")
}

add_client_block() {
  read -rp "  Host alias (e.g. client-acme): " alias
  [[ -z "$alias" ]] && echo "  Alias cannot be empty. Skipping." && return
  read -rp "  HostName: " hostname
  read -rp "  User: " user
  read -rp "  IdentityFile path: " id_file
  new_names+=("$alias")
  new_texts+=("Host $alias
  HostName $hostname
  User $user
  IdentityFile $id_file
  AddKeysToAgent yes
  UseKeychain yes
")
}

# ── Interactive prompts ───────────────────────────────────────────────────────
prompt_new_blocks() {
  echo ""
  echo "==> Add new SSH Host blocks:"
  while true; do
    echo ""
    echo "  1) GitHub"
    echo "  2) Generic host / server"
    echo "  3) Client workspace"
    echo "  4) Done"
    echo ""
    read -rp "  Choice [4]: " choice
    choice="${choice:-4}"
    case "$choice" in
      1) add_github_block ;;
      2) add_generic_block ;;
      3) add_client_block ;;
      4) break ;;
      *) echo "  Invalid choice." ;;
    esac
  done
}

# ── Conflict resolution ───────────────────────────────────────────────────────
check_conflicts() {
  local -a keep_names=() keep_texts=()

  for i in "${!new_names[@]}"; do
    local name="${new_names[$i]}"
    local text="${new_texts[$i]}"
    local conflict_idx=-1

    for j in "${!block_names[@]}"; do
      if [[ "${block_types[$j]}" == "active" && "${block_names[$j]}" == "$name" ]]; then
        conflict_idx=$j
        break
      fi
    done

    if [[ $conflict_idx -ge 0 ]]; then
      echo ""
      echo "  CONFLICT: Host '$name' already exists."
      echo ""
      echo "  ── Existing ──────────────────────────────────────────────────"
      echo "${block_texts[$conflict_idx]}"
      echo "  ── New ───────────────────────────────────────────────────────"
      echo "$text"
      echo ""
      read -rp "  [K]eep existing / [U]se new / [S]kip: " res
      res="${res:-K}"
      case "$res" in
        [Uu]) block_texts[$conflict_idx]="$text" ; echo "  Using new block." ;;
        [Ss]) echo "  Skipped." ;;
        *)    echo "  Keeping existing." ;;
      esac
    else
      keep_names+=("$name")
      keep_texts+=("$text")
    fi
  done

  new_names=("${keep_names[@]+"${keep_names[@]}"}")
  new_texts=("${keep_texts[@]+"${keep_texts[@]}"}")
}

# ── Build merged config string ────────────────────────────────────────────────
build_config() {
  local result=""

  if [[ -n "$global_section" ]]; then
    result+="$global_section"
  else
    result+="# SSH Config — managed by dotfiles"$'\n'
    result+="# Regenerate: just setup-ssh-config"$'\n'
    result+=$'\n'
    result+="AddKeysToAgent yes"$'\n'
    result+="UseKeychain yes"$'\n'
    result+=$'\n'
  fi

  # Separate wildcard Host * block so it always goes last
  local wildcard_text=""
  local -a regular_names=() regular_types=() regular_texts=()

  for i in "${!block_names[@]}"; do
    if [[ "${block_names[$i]}" == "*" && "${block_types[$i]}" == "active" ]]; then
      wildcard_text="${block_texts[$i]}"
    else
      regular_names+=("${block_names[$i]}")
      regular_types+=("${block_types[$i]}")
      regular_texts+=("${block_texts[$i]}")
    fi
  done

  # Existing blocks (triaged)
  for i in "${!regular_names[@]}"; do
    result+="${regular_texts[$i]}"
    [[ "${regular_texts[$i]}" != *$'\n\n' ]] && result+=$'\n'
  done

  # New blocks
  for i in "${!new_names[@]}"; do
    result+="${new_texts[$i]}"
    [[ "${new_texts[$i]}" != *$'\n\n' ]] && result+=$'\n'
  done

  # Wildcard block always last
  if [[ -n "$wildcard_text" ]]; then
    result+="$wildcard_text"
  fi

  printf '%s' "$result"
}

# ── Preview + write ───────────────────────────────────────────────────────────
preview_and_confirm() {
  local merged
  merged=$(build_config)

  echo ""
  echo "==> Preview of ~/.ssh/config:"
  echo "──────────────────────────────────────────────────────────────────"
  echo "$merged"
  echo "──────────────────────────────────────────────────────────────────"
  echo ""
  read -rp "Write this config? [Y/n]: " confirm
  confirm="${confirm:-Y}"
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted. No changes made."
    exit 0
  fi

  if [[ -f "$SSH_CONFIG" ]]; then
    cp "$SSH_CONFIG" "$SSH_CONFIG_BAK"
    echo "  Backed up existing config to $SSH_CONFIG_BAK"
  fi

  mkdir -p "$(dirname "$SSH_CONFIG")"
  chmod 700 "$(dirname "$SSH_CONFIG")"
  printf '%s' "$merged" > "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"
  echo ""
  echo "  Written to $SSH_CONFIG"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  echo "==> SSH Config Builder"

  if [[ -f "$SSH_CONFIG" ]]; then
    echo "    Found existing ~/.ssh/config"
    parse_config "$SSH_CONFIG"
    triage_commented_blocks
  else
    echo "    No existing ~/.ssh/config — starting fresh."
  fi

  prompt_new_blocks

  if [[ ${#new_names[@]} -gt 0 ]]; then
    check_conflicts
  fi

  preview_and_confirm
}

main
