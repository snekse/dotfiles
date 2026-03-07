---
name: justfile-edit
description: >
  This skill should be used whenever a Justfile is edited — including when targets are added,
  removed, renamed, or when a recipe's behavior is materially changed. Trigger this skill any
  time the user asks to "add a just target", "update the Justfile", "add a recipe to the
  Justfile", "remove a just target", or similar. After editing a Justfile, check the sibling
  README.md and keep documentation in sync.
version: 1.0.0
---

# Justfile Edit Skill

After every Justfile edit, check the sibling README and keep documentation in sync.

## Step 1: Locate the README

Find the directory containing the edited Justfile. Look for a `README.md` in that same directory.

- No README present → stop, do nothing.
- README present → continue to Step 2.

## Step 2: Determine whether the README documents the Justfile

Scan the README for evidence of Justfile documentation:
- References to `just` or `just <target>` syntax
- A list or table of targets with descriptions
- Sections titled "Commands", "Tasks", "Usage", "Development", or similar

**README documents the Justfile → go to Step 3.**
**README does not document the Justfile → go to Step 4.**

## Step 3: Update existing Justfile documentation

Assess the nature of the change made to the Justfile:

| Change type | Action |
|---|---|
| New target added | Add it to the README's command list with a brief description |
| Target removed | Remove it from the README |
| Target renamed | Update all references in the README |
| Recipe behavior materially changed | Update the relevant description |
| Internal refactor only (identical behavior) | No README update needed |

Make the update. Match the existing documentation style and format already present in the README.

## Step 4: README exists but has no Justfile documentation

Before asking, check memory files for a `## justfile_readme_skip` section. If the current project's root path is listed there, stop — the user previously declined and should not be asked again.

If not in the skip list, ask the user:

> "The README doesn't currently document the Justfile targets. Would you like me to add a section for the available `just` commands?"

- **Yes** → Draft a new section listing all current targets with descriptions. Source descriptions from inline comments in the Justfile (`# comment` above a target) or infer from target names. Insert the section in a logical location (after intro, within or before a "Usage" or "Development" section).
- **No** → Record the project root path in memory under `## justfile_readme_skip` so the question is never asked again for this project:

```markdown
## justfile_readme_skip
- /path/to/project
- /path/to/another-project
```
