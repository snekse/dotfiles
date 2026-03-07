# =============================================================================
# Homebrew helpers
# =============================================================================

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
    local match_info
    match_info=$(grep -nF "\"$pkg_name\"" "$brewfile" 2>/dev/null | head -1)
    [[ -z "$match_info" ]] && continue

    local line="${match_info#*:}"
    line="${line#"${line%%[! ]*}"}"  # trim leading whitespace

    local pkg_type mas_id=""
    if   [[ "$line" == brew\ * ]];  then pkg_type="formula"
    elif [[ "$line" == cask\ * ]];  then pkg_type="cask"
    elif [[ "$line" == tap\ * ]];   then pkg_type="tap"
    elif [[ "$line" == mas\ * ]];   then
      pkg_type="mas"
      mas_id=$(echo "$line" | grep -oE 'id: [0-9]+' | grep -oE '[0-9]+')
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

  # Step 2: Build display of what will happen, then confirm
  echo "Found '$pkg_name':"
  for i in "${!found_files[@]}"; do
    echo "  $(basename "${found_files[$i]}"): ${found_lines[$i]}"
  done
  echo ""
  echo "This will:"
  for i in "${!found_types[@]}"; do
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

  local dirty
  dirty=$(git -C "$DOTFILES" status --porcelain)
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
  for i in "${!found_types[@]}"; do
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

  # Step 5: Remove lines from Brewfiles
  # Re-find line numbers after pull in case the file changed
  for i in "${!found_files[@]}"; do
    local file="${found_files[$i]}"
    local line_num
    line_num=$(grep -nF "\"$pkg_name\"" "$file" 2>/dev/null | head -1 | cut -d: -f1)
    if [[ -n "$line_num" ]]; then
      sed -i '' "${line_num}d" "$file"
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

  dirty=$(git -C "$DOTFILES" status --porcelain)
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
  local BREWFILE="$DOTFILES/Brewfile"
  local pkg_type=""
  local user_specified_type=false
  local pkg_name=""
  local optional=false

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
      -o)        optional=true; shift ;;
      --formula) pkg_type="formula"; user_specified_type=true; shift ;;
      --cask)    pkg_type="cask";    user_specified_type=true; shift ;;
      --tap)     pkg_type="tap";     user_specified_type=true; shift ;;
      -*)        echo "brew-add: unknown flag '$1'"; return 1 ;;
      *)         pkg_name="$1"; shift ;;
    esac
  done

  if [[ -z "$pkg_name" ]]; then
    echo "Usage: brew-add [-o] [--cask|--tap|--formula] <package>"
    return 1
  fi

  [[ "$optional" == "true" ]] && BREWFILE="$DOTFILES/Brewfile.optional"

  # Step 1: Git pull
  echo "Pulling latest dotfiles..."
  if ! git -C "$DOTFILES" pull origin main; then
    echo "brew-add: git pull failed — aborting"
    return 1
  fi

  local dirty
  dirty=$(git -C "$DOTFILES" status --porcelain)
  if [[ -n "$dirty" ]]; then
    echo ""
    echo "Warning: dotfiles repo is dirty after pull:"
    echo "$dirty"
    echo ""
    read -q "?Continue anyway? (y/n) " || { echo; return 1; }
    echo
  fi

  # Step 2: Auto-detect type if not specified
  if [[ "$user_specified_type" == "false" ]]; then
    echo "Detecting '$pkg_name' in Homebrew..."
    local info_json
    info_json=$(brew info --json=v2 "$pkg_name" 2>/dev/null)

    if [[ $? -ne 0 ]] || [[ -z "$info_json" ]]; then
      echo "brew-add: '$pkg_name' not found in Homebrew"
      return 1
    fi

    local has_formula has_cask
    has_formula=$(echo "$info_json" | jq -r '.formulae | length')
    has_cask=$(echo "$info_json" | jq -r '.casks | length')

    if [[ "$has_cask" -gt 0 && "$has_formula" -eq 0 ]]; then
      pkg_type="cask"
    elif [[ "$has_formula" -gt 0 ]]; then
      pkg_type="formula"
    else
      echo "brew-add: could not determine type for '$pkg_name'"
      return 1
    fi

    echo "Detected: $pkg_type"
  fi

  # Step 3: Format Brewfile line
  local brewfile_line
  case "$pkg_type" in
    cask)    brewfile_line="cask \"$pkg_name\"" ;;
    tap)     brewfile_line="tap \"$pkg_name\"" ;;
    *)       brewfile_line="brew \"$pkg_name\"" ;;
  esac

  # Step 4: Check for duplicates
  if grep -qF "$brewfile_line" "$BREWFILE"; then
    echo "brew-add: '$pkg_name' is already in $(basename "$BREWFILE") ($brewfile_line)"
    return 0
  fi

  # Step 5: Append to Brewfile
  echo "$brewfile_line" >> "$BREWFILE"
  echo "Added to $(basename "$BREWFILE"): $brewfile_line"

  # Step 6: Install
  echo ""
  local install_failed=false
  if [[ "$optional" == "true" ]]; then
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
        install_failed=true
      fi
    else
      echo "Skipping install — '$pkg_name' is recorded in Brewfile.optional for later."
    fi
  else
    echo "Running brew bundle..."
    if ! brew bundle --file="$BREWFILE"; then
      echo ""
      echo "brew-add: brew bundle failed"
      install_failed=true
    fi

    if [[ "$install_failed" == "true" ]]; then
      if [[ "$user_specified_type" == "true" ]]; then
        echo "Checking whether '$pkg_name' has a different type..."
        local info_json
        info_json=$(brew info --json=v2 "$pkg_name" 2>/dev/null)
        if [[ $? -eq 0 && -n "$info_json" ]]; then
          local has_formula has_cask
          has_formula=$(echo "$info_json" | jq -r '.formulae | length')
          has_cask=$(echo "$info_json" | jq -r '.casks | length')
          if [[ "$has_cask" -gt 0 && "$pkg_type" != "cask" ]]; then
            echo "Hint: '$pkg_name' appears to be a cask — try: brew-add --cask $pkg_name"
          elif [[ "$has_formula" -gt 0 && "$pkg_type" != "formula" ]]; then
            echo "Hint: '$pkg_name' appears to be a formula — try: brew-add $pkg_name"
          fi
        fi
      fi
      git -C "$DOTFILES" checkout -- "$BREWFILE"
      echo "Reverted $(basename "$BREWFILE")"
      return 1
    fi
  fi

  # Step 7: Commit
  local brewfile_label
  [[ "$optional" == "true" ]] && brewfile_label="Brewfile.optional" || brewfile_label="Brewfile"
  echo ""
  echo "Committing $brewfile_label..."
  git -C "$DOTFILES" add "$BREWFILE"
  git -C "$DOTFILES" commit -m "brew: add $pkg_name"

  dirty=$(git -C "$DOTFILES" status --porcelain)
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
