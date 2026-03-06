# Claude Personalities

This repository is a collection of Claude personalities and the skills to use them.

A personality is a set of instructions stored in a `PERSONALITY.md` file. Personalities adjust Claude's response style, tone, and interaction model for an entire session. Unlike skills — which complete a specific task — a personality defines a mindset Claude operates in continuously.

Personalities are invoked via the `adopt-personality` skill, which reads the available personalities and lets the user choose one at the start of a session.

## Project structure

```
claude-personalities/
├── personalities/
│   └── {personality-name}/
│       └── PERSONALITY.md
├── skills/
│   └── adopt-personality/
│       └── SKILL.md
└── setup.sh
```

### PERSONALITY.md format

Each personality is defined by a `PERSONALITY.md` file with the following structure:

```markdown
---
name: [Name of the personality]
description: [Short description of the personality]
---

# Task
[How Claude should approach tasks in this personality]

# Response Format
[How Claude should format responses]

# Interaction style
[How Claude should interact with the user]
```

## Setup

Run the setup script from the repo root:

```bash
./setup.sh
```

The script does two things:

**1. Skill symlinks**

For each skill in `skills/`, it asks whether you want to symlink it into `~/.claude/skills/`. Per skill:
- If the skill doesn't exist yet: creates the symlink
- If it already exists: asks whether to overwrite it
- Skips the skill if you decline

**2. Read access**

Asks whether to add a `Read` permission for this repo to `~/.claude/settings.json`. This allows Claude to read personality files from this directory. If the permission is already present it does nothing.

> Requires `jq`: `brew install jq`

## Existing Personalities

### Terminal Documentation

**Location**: `personalities/terminal-documentation/PERSONALITY.md`

---

**Function**:

This claude personality turns your claude code session into an interactive terminal documentation. Claude will produce detailed descriptions of terminal commands required to execute a desired task. It presents all commands needed to execute the task and describes the relevant flags. In case the user has further questions the explanation is given concisely, as if reading a documentation page. Answers are kept as brief as possible to mimic the formatting and setup of traditional cli documentations. This is not a conversational personality but rather turns claude into a tailored and interactive `--help` page for all your terminal commands.

---

#### Examples

##### Basic example

Question: How can I create a PR with the github cli?

> ## Solution
>
> Use the GitHub CLI (gh) to create a pull request from the current branch against a target branch in the remote repository.
>
> _Needed commands:_
>
> **gh pr create**
>
> Creates a new pull request on GitHub for the current branch.
>
> - --title, -t   : string  (PR title)
> - --body, -b    : string  (PR description body)
> - --base, -B    : string  (target branch to merge into, defaults to repo default)
> - --head, -H    : string  (source branch, defaults to current branch)
> - --draft, -d   : flag    (mark PR as draft)
> - --assignee    : string  (assign to a user, use @me for self)
> - --label, -l   : string  (apply a label)
> - --web, -w     : flag    (open in browser after creation)
>
> Basic usage with title and body:
>
> `gh pr create --title "Add login feature" --body "Implements OAuth2 login flow"`
>
> Create a draft PR targeting a specific base branch:
>
> `gh pr create --title "WIP: refactor auth" --body "In progress" --base develop --draft`
>
> Open interactive prompts to fill in details (omit flags):
>
> `gh pr create`

##### Conversation with interpreting command output

Question: How can I change a repositories visibility to public?

> ## Solution
>
> Use gh repo edit to change repository visibility directly without constructing a raw API call.
>
> _Needed commands:_
>
> **gh repo edit**
>
> Modifies repository settings using a higher-level CLI interface.
>
> - --visibility  : string  (public, private, or internal)
> - --accept-visibility-change-consequences : flag (required acknowledgement when changing to public)
>
> `gh repo edit {owner}/{repo} --visibility public --accept-visibility-change-consequences`

Terminal output:
```json
{
  "url": "https://api.github.com/repos/{owner}/{repo}/branches/main/protection",
  "required_signatures": {
    "url": "https://api.github.com/repos/{owner}/{repo}/branches/main/protection/required_signatures",
    "enabled": false
  },
  "enforce_admins": {
    "url": "https://api.github.com/repos/{owner}/{repo}/branches/main/protection/enforce_admins",
    "enabled": false
  },
  "required_linear_history": {
    "enabled": true
  },
  "allow_force_pushes": {
    "enabled": false
  },
  "allow_deletions": {
    "enabled": false
  },
  "block_creations": {
    "enabled": false
  },
  "required_conversation_resolution": {
    "enabled": false
  },
  "lock_branch": {
    "enabled": true
  },
  "allow_fork_syncing": {
    "enabled": false
  }
}
```

> lock_branch: true is a problem — it makes main entirely read-only, preventing any direct pushes including your own. This needs to be corrected.
>
> ---
>
> **Solution**
>
> Patch the branch protection to explicitly disable lock_branch.
>
> _Needed commands:_
>
> **gh api (branch protection)**
>
> Updates the branch protection rule to unlock the branch.
>
> - --method, -X  : string  (HTTP method)
> - -F            : key=val (typed field — booleans/numbers)
>
> ```
> gh api --method PUT repos/{owner}/{repo}/branches/main/protection \
>   -F required_status_checks=null \
>   -F enforce_admins=false \
>   -F restrictions=null \
>   -F required_pull_request_reviews=null \
>   -F allow_force_pushes=false \
>   -F allow_deletions=false \
>   -F required_linear_history=true \
>   -F lock_branch=false
> ```
>
> Verify afterwards:
>
> ```
> gh api repos/{owner}/{repo}/branches/main/protection \
>   --jq '{lock_branch: .lock_branch.enabled, allow_force_pushes: .allow_force_pushes.enabled,
> allow_deletions: .allow_deletions.enabled, linear_history: .required_linear_history.enabled}'
> ```

Terminal output:
```json
{
  "allow_deletions": false,
  "allow_force_pushes": false,
  "linear_history": true,
  "lock_branch": false
}
```

> Settings are correctly configured.

##### Conversation with follow up

Question: How can I determine the difference between two text files?

> ## Solution
>
> Use diff to compare two files line by line and display what has changed.
>
> _Needed commands:_
>
> **diff**
>
> Compares two files and outputs the differing lines.
>
> - -u, --unified  : flag    (show N lines of context around changes, default 3)
> - -i             : flag    (ignore case differences)
> - --color        : flag    (colorize the output)
>
> `diff --color -u file1.txt file2.txt`
>
> Output legend:
> - Lines prefixed with - exist only in file1.txt
> - Lines prefixed with + exist only in file2.txt
> - Unprefixed lines are identical in both files

Followup: The paths are ~/foo.txt ~/bar.txt what is the command going to look like?

> `diff --color -u ~/foo.txt ~/bar.txt`

##### Conversation with OS aware response

Question: How can I pipe my clipboard contents into another command?

> ## Solution
>
> Use pbpaste (macOS) to read clipboard contents and pipe it into another command.
>
> _Needed commands:_
>
> **pbpaste**
>
> Outputs the current clipboard contents to stdout.
>
> `pbpaste | <command>`
>
> For example, to word-count the clipboard contents:
>
> `pbpaste | wc -w`
