# =============================================================================
# Homebrew helpers
# =============================================================================

# Add a package to the dotfiles Brewfile, install it, and sync the repo.
#
# Usage:
#   brew-add <package>              # auto-detect formula vs cask
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

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        echo "Usage: brew-add [--cask|--tap|--formula] <package>"
        echo ""
        echo "Add a package to the dotfiles Brewfile, install it, and sync the repo."
        echo ""
        echo "Options:"
        echo "  --formula   Force add as a Homebrew formula (default when auto-detected)"
        echo "  --cask      Force add as a Homebrew cask (GUI apps)"
        echo "  --tap       Add a Homebrew tap instead of a package"
        echo "  --help, -h  Show this help message"
        echo ""
        echo "Examples:"
        echo "  brew-add ripgrep              # auto-detect type"
        echo "  brew-add --cask firefox       # explicitly add as cask"
        echo "  brew-add --tap homebrew/cask  # add a tap"
        echo ""
        echo "Workflow: git pull → detect type → add to Brewfile → brew bundle → git commit → git push"
        return 0
        ;;
      --formula) pkg_type="formula"; user_specified_type=true; shift ;;
      --cask)    pkg_type="cask";    user_specified_type=true; shift ;;
      --tap)     pkg_type="tap";     user_specified_type=true; shift ;;
      -*)        echo "brew-add: unknown flag '$1'"; return 1 ;;
      *)         pkg_name="$1"; shift ;;
    esac
  done

  if [[ -z "$pkg_name" ]]; then
    echo "Usage: brew-add [--cask|--tap|--formula] <package>"
    return 1
  fi

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
    echo "brew-add: '$pkg_name' is already in the Brewfile ($brewfile_line)"
    return 0
  fi

  # Step 5: Append to Brewfile
  echo "$brewfile_line" >> "$BREWFILE"
  echo "Added to Brewfile: $brewfile_line"

  # Step 6: Run brew bundle
  echo ""
  echo "Running brew bundle..."
  if ! brew bundle --file="$BREWFILE"; then
    echo ""
    echo "brew-add: brew bundle failed"

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
    echo "Reverted Brewfile"
    return 1
  fi

  # Step 7: Commit
  echo ""
  echo "Committing Brewfile..."
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
  echo "Done! '$pkg_name' added, installed, and pushed."
}
