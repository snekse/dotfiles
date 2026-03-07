# manage-git-ignore

This command manages two related ignore files in the dotfiles repo that must be kept in sync:

- **`~/dotfiles/.gitignore`** — prevents files from being committed to git. Uses standard glob syntax.
- **`~/dotfiles/git/.stow-local-ignore`** — prevents files from being symlinked into `$HOME` by GNU Stow. Uses **Perl regex matched against the filename component only** (not the full path). This file overrides stow's built-in defaults for the `git/` package (necessary so that `.gitignore` itself gets stowed to `~/.gitignore`).

## Syntax translation

| Intent | .gitignore (glob) | .stow-local-ignore (Perl regex) |
|---|---|---|
| Exact filename | `.npmrc` | `^\.npmrc$` |
| Directory | `.aws/` | `^\.aws$` |
| Any `_history` file | `.*_history` | `\..+_history` |
| Extension | `*.pem` | `.*\.pem$` |

**Critical stow constraint**: patterns match only the last path component (filename or dirname), never a full path. You cannot target `.docker/config.json` specifically — only `.docker/` (whole dir) or `config.json` (too broad). When precision isn't possible, ignore the parent directory and note the trade-off.

## Mirrored sections — must exist in both files

When a pattern is added to one, add the equivalent to the other.

1. **Cloud & infrastructure credentials** — `.aws/`, `.azure/`, `.kube/`, `.terraform.d/`
2. **Package manager & tool credentials** — `.npmrc`, `.pypirc`, `.gem/`, `.docker/`, `.git-credentials`
3. **Shell & REPL history** — `.*_history` glob / `\..+_history` regex
4. **Encryption & identity** — `.gnupg/`, `.gpg/`, `*.pem`, `*.key`, `*.pkcs12`

## Stow-only sections — no gitignore counterpart needed

These prevent repo/tooling files from polluting `$HOME` but don't need to be gitignored:

- Stow metadata, VCS internals (`.git`, `.hg`, etc.)
- Backup and temp files (`*~`, `*.orig`, etc.)
- Compiled artifacts (`*.o`, `*.pyc`, `*.zwc`, etc.)
- Build directories
- Editor/IDE config (`^/.editorconfig`, `^/.cursor`, etc.)
- AI instruction files (`^/CLAUDE.md`, `^/AGENTS.md`, etc.)
- JS tooling (`^/node_modules`)

## Adding a new pattern

1. Identify its category (mirrored or stow-only).
2. For mirrored patterns, show both translations before editing:
   ```
   .gitignore:          .secretfile
   .stow-local-ignore:  ^\.secretfile$
   ```
   Note any cases where stow's filename-only matching forces a less precise pattern than gitignore.
3. Insert into the correct section in both files.

## Auditing for drift

Read both files, then for each mirrored category check:

- A pattern in `.gitignore` with no stow equivalent → potential symlink leak
- A pattern in the mirrored sections of `.stow-local-ignore` with no gitignore equivalent → potential commit risk
- Patterns that exist in both but are inconsistent (e.g., gitignore has `.gem/credentials` but stow has `^\.gem$`) → flag and propose alignment

Present findings as a clear diff-style report and propose specific fixes.
