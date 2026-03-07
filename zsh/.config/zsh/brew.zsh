# =============================================================================
# Homebrew helpers
# =============================================================================

# Detect whether a package is a "formula", "cask", or "" (not found).
# Uses brew exit codes only — no JSON, no jq.
_brew_detect_type() {
  local pkg="$1"
  if HOMEBREW_NO_AUTO_UPDATE=1 brew info --cask "$pkg" &>/dev/null; then
    echo "cask"
  elif HOMEBREW_NO_AUTO_UPDATE=1 brew info --json "$pkg" &>/dev/null; then
    echo "formula"
  else
    echo ""
  fi
}

# Remove a package from the Brewfile (or Brewfile.optional), uninstall it,
# and sync the repo.
#
# Usage:
#   brew-remove <package>
#
# Workflow: search Brewfiles → confirm → git pull → uninstall → remove line → commit → push
brew-remove() {
  local DOTFILES="$HOME/dotfiles"
  local pkg_name=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        echo "Usage: brew-remove <package>"
        echo ""
        echo "Uninstall a package and remove it from Brewfile or Brewfile.optional,"
        echo "then commit and push the change."
        echo ""
        echo "Examples:"
        echo "  brew-remove ripgrep"
        echo "  brew-remove nikitabobko/tap/aerospace"
        echo "  brew-remove \"Slack for Desktop\"   # mas app (use quoted name)"
        return 0
        ;;
      -*) echo "brew-remove: unknown flag '$1'"; return 1 ;;
      *)  pkg_name="$1"; shift ;;
    esac
  done

  if [[ -z "$pkg_name" ]]; then
    echo "Usage: brew-remove <package>"
    return 1
  fi

  # Step 1: Search both Brewfiles for the package name
  local brewfiles=("$DOTFILES/Brewfile" "$DOTFILES/Brewfile.optional")
  local found_files=()
  local found_lines=()
  local found_types=()
  local found_mas_ids=()

  for brewfile in "${brewfiles[@]}"; do
    local match_info=$(grep -nF "\"$pkg_name\"" "$brewfile" 2>/dev/null | head -1)
    [[ -z "$match_info" ]] && continue

    local line="${match_info#*:}"

    local pkg_type mas_id=""
    if   [[ "$line" == brew\ * ]]; then pkg_type="formula"
    elif [[ "$line" == cask\ * ]]; then pkg_type="cask"
    elif [[ "$line" == tap\ * ]];  then pkg_type="tap"
    elif [[ "$line" == mas\ * ]];  then
      pkg_type="mas"
      mas_id="${line##*, id: }"
    else
      pkg_type="unknown"
    fi

    found_files+=("$brewfile")
    found_lines+=("$line")
    found_types+=("$pkg_type")
    found_mas_ids+=("$mas_id")
  done

  if [[ ${#found_files[@]} -eq 0 ]]; then
    echo "brew-remove: '$pkg_name' not found in Brewfile or Brewfile.optional"
    return 1
  fi

  # Step 2: Show what will happen, then confirm
  echo "Found '$pkg_name':"
  for i in {1..${#found_files[@]}}; do
    echo "  $(basename "${found_files[$i]}"): ${found_lines[$i]}"
  done
  echo ""
  echo "This will:"
  for i in {1..${#found_types[@]}}; do
    case "${found_types[$i]}" in
      formula) echo "  - Run: brew uninstall \"$pkg_name\"" ;;
      cask)    echo "  - Run: brew uninstall --cask \"$pkg_name\"" ;;
      tap)     echo "  - Run: brew untap \"$pkg_name\"" ;;
      mas)     echo "  - Run: mas uninstall ${found_mas_ids[$i]}" ;;
      *)       echo "  - Skip uninstall (unknown type — remove from brew manually)" ;;
    esac
    echo "  - Remove from: $(basename "${found_files[$i]}")"
  done
  echo "  - Commit and push the changes"
  echo ""
  read -q "?Are you sure? (y/n) "
  local confirm=$?
  echo
  if [[ $confirm -ne 0 ]]; then
    echo "Nothing was changed."
    return 0
  fi

  # Step 3: Git pull
  echo ""
  echo "Pulling latest dotfiles..."
  if ! git -C "$DOTFILES" pull origin main; then
    echo "brew-remove: git pull failed — aborting"
    return 1
  fi

  local dirty=$(git -C "$DOTFILES" status --porcelain)
  if [[ -n "$dirty" ]]; then
    echo ""
    echo "Warning: dotfiles repo is dirty after pull:"
    echo "$dirty"
    echo ""
    read -q "?Continue anyway? (y/n) "
    local cont=$?
    echo
    [[ $cont -ne 0 ]] && return 1
  fi

  # Step 4: Uninstall from brew
  for i in {1..${#found_types[@]}}; do
    case "${found_types[$i]}" in
      formula)
        echo "Running: brew uninstall \"$pkg_name\""
        brew uninstall "$pkg_name" || echo "Warning: uninstall failed, continuing..."
        ;;
      cask)
        echo "Running: brew uninstall --cask \"$pkg_name\""
        brew uninstall --cask "$pkg_name" || echo "Warning: uninstall failed, continuing..."
        ;;
      tap)
        echo "Running: brew untap \"$pkg_name\""
        brew untap "$pkg_name" || echo "Warning: untap failed, continuing..."
        ;;
      mas)
        local mas_id="${found_mas_ids[$i]}"
        echo "Running: mas uninstall $mas_id"
        mas uninstall "$mas_id" || echo "Warning: mas uninstall failed, continuing..."
        ;;
      *)
        echo "Skipping uninstall for '${found_lines[$i]}' (unknown type)"
        ;;
    esac
  done

  # Step 5: Remove lines from Brewfiles (re-check after pull in case file changed)
  for i in {1..${#found_files[@]}}; do
    local file="${found_files[$i]}"
    if grep -qF "\"$pkg_name\"" "$file" 2>/dev/null; then
      grep -vF "\"$pkg_name\"" "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
      echo "Removed from $(basename "$file"): ${found_lines[$i]}"
    else
      echo "Warning: '${found_lines[$i]}' no longer in $(basename "$file") — skipping"
    fi
  done

  # Step 6: Commit
  echo ""
  echo "Committing changes..."
  for file in "${found_files[@]}"; do
    git -C "$DOTFILES" add "$file"
  done
  git -C "$DOTFILES" commit -m "brew: remove $pkg_name"

  local dirty=$(git -C "$DOTFILES" status --porcelain)
  if [[ -n "$dirty" ]]; then
    echo ""
    echo "Warning: repo has unexpected changes after commit:"
    echo "$dirty"
    echo ""
    read -q "?Continue with push? (y/n) "
    local cont=$?
    echo
    [[ $cont -ne 0 ]] && return 0
  fi

  # Step 7: Push
  echo "Pushing to origin main..."
  git -C "$DOTFILES" push origin main
  echo ""
  echo "Done! '$pkg_name' uninstalled and removed from dotfiles."
}

# Add a package to the dotfiles Brewfile, install it, and sync the repo.
#
# Usage:
#   brew-add <package>              # auto-detect formula vs cask → Brewfile
#   brew-add -o <package>           # add to Brewfile.optional instead
#   brew-add --formula <package>    # force formula
#   brew-add --cask <package>       # force cask
#   brew-add --tap <package>        # add a tap
#
# Workflow: git pull → detect type → add to Brewfile → brew bundle → git commit → git push
brew-add() {
  local DOTFILES="$HOME/dotfiles"
  local pkg_type=""
  local user_specified_type=0
  local pkg_name=""
  local optional=0

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        echo "Usage: brew-add [-o] [--cask|--tap|--formula] <package>"
        echo ""
        echo "Add a package to the dotfiles Brewfile, install it, and sync the repo."
        echo ""
        echo "Options:"
        echo "  -o          Add to Brewfile.optional instead of Brewfile"
        echo "  --formula   Force add as a Homebrew formula (default when auto-detected)"
        echo "  --cask      Force add as a Homebrew cask (GUI apps)"
        echo "  --tap       Add a Homebrew tap instead of a package"
        echo "  --help, -h  Show this help message"
        echo ""
        echo "Examples:"
        echo "  brew-add ripgrep                 # auto-detect type → Brewfile"
        echo "  brew-add -o --cask obsidian      # add cask → Brewfile.optional"
        echo "  brew-add --tap homebrew/cask     # add a tap"
        echo ""
        echo "Workflow: git pull → detect type → add to Brewfile → brew bundle → git commit → git push"
        return 0
        ;;
      -o)        optional=1; shift ;;
      --formula) pkg_type="formula"; user_specified_type=1; shift ;;
      --cask)    pkg_type="cask";    user_specified_type=1; shift ;;
      --tap)     pkg_type="tap";     user_specified_type=1; shift ;;
      -*)        echo "brew-add: unknown flag '$1'"; return 1 ;;
      *)         pkg_name="$1"; shift ;;
    esac
  done

  if [[ -z "$pkg_name" ]]; then
    echo "Usage: brew-add [-o] [--cask|--tap|--formula] <package>"
    return 1
  fi

  local BREWFILE
  (( optional )) && BREWFILE="$DOTFILES/Brewfile.optional" || BREWFILE="$DOTFILES/Brewfile"
  local brewfile_label=$(basename "$BREWFILE")

  # Step 1: Git pull
  echo "Pulling latest dotfiles..."
  if ! git -C "$DOTFILES" pull origin main; then
    echo "brew-add: git pull failed — aborting"
    return 1
  fi

  local dirty=$(git -C "$DOTFILES" status --porcelain)
  if [[ -n "$dirty" ]]; then
    echo ""
    echo "Warning: dotfiles repo is dirty after pull:"
    echo "$dirty"
    echo ""
    read -q "?Continue anyway? (y/n) " || { echo; return 1; }
    echo
  fi

  # Step 2: Auto-detect type if not specified
  if (( !user_specified_type )); then
    echo "Detecting '$pkg_name' in Homebrew..."
    pkg_type=$(_brew_detect_type "$pkg_name")
    if [[ -z "$pkg_type" ]]; then
      echo "brew-add: '$pkg_name' not found in Homebrew"
      return 1
    fi
    echo "Detected: $pkg_type"
  fi

  # Step 3: Format Brewfile line
  local brewfile_line
  case "$pkg_type" in
    cask) brewfile_line="cask \"$pkg_name\"" ;;
    tap)  brewfile_line="tap \"$pkg_name\"" ;;
    *)    brewfile_line="brew \"$pkg_name\"" ;;
  esac

  # Step 4: Check for duplicates
  if grep -qF "$brewfile_line" "$BREWFILE"; then
    echo "brew-add: '$pkg_name' is already in $brewfile_label ($brewfile_line)"
    return 0
  fi

  # Step 5: Append to Brewfile
  echo "$brewfile_line" >> "$BREWFILE"
  echo "Added to $brewfile_label: $brewfile_line"

  # Step 6: Install
  echo ""
  if (( optional )); then
    read -q "?Install '$pkg_name' now? Answering 'N' will just add the pkg to \`Brewfile.optional\`. (y/n) "
    local install_now=$?
    echo
    if [[ $install_now -eq 0 ]]; then
      echo "Running brew install..."
      local brew_install_cmd=(brew install)
      [[ "$pkg_type" == "cask" ]] && brew_install_cmd+=(--cask)
      [[ "$pkg_type" == "tap"  ]] && brew_install_cmd=(brew tap)
      if ! "${brew_install_cmd[@]}" "$pkg_name"; then
        echo ""
        echo "brew-add: install failed"
      fi
    else
      echo "Skipping install — '$pkg_name' is recorded in Brewfile.optional for later."
    fi
  else
    echo "Running brew bundle..."
    if ! brew bundle --file="$BREWFILE"; then
      echo ""
      echo "brew-add: brew bundle failed"
      if (( user_specified_type )); then
        local detected_type=$(_brew_detect_type "$pkg_name")
        if [[ -n "$detected_type" && "$detected_type" != "$pkg_type" ]]; then
          echo "Hint: '$pkg_name' appears to be a $detected_type — try: brew-add --$detected_type $pkg_name"
        fi
      fi
      git -C "$DOTFILES" checkout -- "$BREWFILE"
      echo "Reverted $brewfile_label"
      return 1
    fi
  fi

  # Step 7: Commit
  echo ""
  echo "Committing $brewfile_label..."
  git -C "$DOTFILES" add "$BREWFILE"
  git -C "$DOTFILES" commit -m "brew: add $pkg_name"

  local dirty=$(git -C "$DOTFILES" status --porcelain)
  if [[ -n "$dirty" ]]; then
    echo ""
    echo "Warning: repo has unexpected changes after commit:"
    echo "$dirty"
    echo ""
    read -q "?Continue with push? (y/n) " || { echo; return 0; }
    echo
  fi

  # Step 8: Push
  echo "Pushing to origin main..."
  git -C "$DOTFILES" push origin main
  echo ""
  echo "Done! '$pkg_name' added to $brewfile_label, installed, and pushed."
}
