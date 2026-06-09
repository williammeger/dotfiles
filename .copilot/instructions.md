# Global Copilot Instructions

## Agent Routing

Always read `~/.copilot/agent-routing.md` at session start. It defines a routing
protocol that maps your environment (CWD, pane title, git state) to a specific
operating mode. Follow it deterministically — do not ask the user what they want
to do when the context already tells you.

## Plan Writing

Before writing any plan:

1. **Infer the name from git** — run `git branch --show-current` or read the worktree
   directory name. Use that as the plan filename. Do this automatically without asking.
2. **No branch?** — prompt for a temporary name. It can be renamed once a Jira ticket
   lands or work begins.
3. **Save to `~/.copilot/plans/<name>.md`** — named by branch, not session UUID.
   This keeps plans shell auto-complete friendly (`~/.copilot/plans/ANDCORE-<tab>`).
4. **Use this format at the top of every plan:**
   ```markdown
   # ANDCORE-123

   ## Plan Name

   Brief description of the goal.
   ```
   The H1 is the Jira ticket ID extracted from the branch name. The H2 is a short human
   title for the plan. The paragraph is one or two sentences stating the goal.

## Git Identity & Credential Hygiene

**CRITICAL — always enforce these rules when making git commits:**

1. **Never add a Co-authored-by trailer** to any commit. Do not include
   `Co-authored-by: Copilot <...>` or any other co-author line unless the
   user explicitly requests it.

2. **Verify git identity before committing.** Before any `git commit`, run
   `git config user.email` and confirm the result is appropriate for the
   target repository:
   - Personal repos (e.g. `~/.cfg` bare repo, any `github-personal` remote):
     must use `wmeger14@gmail.com`
   - Work repos: must use `william.meger@crunchyroll.com`
   - If the email is wrong, abort and alert the user — do NOT commit.

3. **Never commit secrets, tokens, or credentials** to any repository.
   Scan staged diffs for API keys, tokens, passwords, and private keys
   before committing.

4. **Never expose work identity in personal repos** (or vice versa). This
   includes author/committer email, internal hostnames, project names, or
   any information that links the two identities.

5. **Do not mention spotless, formatting, or detekt in commit messages** unless
   the change is non-trivial and alters the semantics of the source code.
   Routine auto-formatting and lint fixes do not warrant commit message noise.

## Dotfiles Bare Git Repo

Dotfiles are managed via a bare git repo at `~/.cfg` with work tree `$HOME`.

- **Always use the `config` shell alias** for all dotfiles git operations — never use `git --git-dir=...` directly
  ```
  config add ~/.tmux.conf
  config commit -m "..."
  config status
  ```
- The `config` alias is defined in `~/.aliases` as:
  `alias config="/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME"`
- Commits are personal — the global rule against `Co-authored-by: Copilot` trailers applies here too.

## Default Repository

Unless otherwise specified, all code-related tasks (PRs, issues, branches, etc.) refer to:
- **Repo:** `crunchyroll/cr-android-app`
- **GitHub URL:** https://github.com/crunchyroll/cr-android-app

This is a monorepo containing both the Android Mobile and AndroidTV codebases.

- **Local path:** `~/dev/cr-android-app`
- **Project-level Copilot instructions:** `.github/copilot-instructions.md` in the repo root — always reference these for coding conventions, build tasks, testing patterns, and project structure details.

We follow trunk-based development.

## Git Worktrees

When creating a git worktree, always place it in the sibling `.worktrees` directory:

```
~/dev/cr-android-app.worktrees/<TICKET_ID>
```

- **Directory name**: Use the Jira ticket ID (e.g., `ANDCORE-302`)
- **Branch name**: Follow standard branch naming convention (`ANDCORE-302-descriptive-name`)
- **Base**: Always create from a fresh `origin/main` fetch

Example:
```bash
git fetch origin main --quiet
git worktree add ~/dev/cr-android-app.worktrees/ANDCORE-302 -b ANDCORE-302-audit-objects-endpoint origin/main
```

## Team

The Android Mobile and AndroidTV teams have merged into one unified Android team, divided into two sub-teams:
- **UI Team** — feature development
- **Core Team** — infrastructure and architecture

Here are my teammates and their GitHub handles:

| Name | GitHub Handle |
|---|---|
| Omar Viscarra | @Omievee |
| Santosh Bobbili | @santoshbobbili321 |
| Esther Song | @song-esther |
| Christian White | @christian-whiteCR |
| Charles Washington | @charlesEnigma |
| Will Meger | @william-meger |
| Raju Kovvuru | @raju-kovvuru *(manager)* |
| Jon Abulencia | @jabulenc |
| Carlos Pineda | @carlospineda-cr |
| Luiz Cristofori | @cr-luizcristofori |
| Siddartth Vasantha Prabhu | @Siddartth |
| Balazs Karath | @karathb |

## Confluence

The team operates in the **Android** Confluence space:
- **Space key:** `AN`
- **Homepage:** https://crunchyroll.atlassian.net/wiki/spaces/AN/overview?homepageId=73302018
- **Cloud ID:** `crunchyroll.atlassian.net`

Unless otherwise specified, any Confluence-related tasks refer to this space.

### Tech & Discovery Docs

Tech docs and discovery documentation live in the **TDD** directory:
- **Page ID:** `73327537`
- **URL:** https://crunchyroll.atlassian.net/wiki/spaces/AN/pages/73327537/TDD

This is the default parent location for new tech/discovery docs.

### Creating New Documents

When creating a new Confluence document:
1. **Ask for the document type** — default options are **Standard** or **Live Doc** (the most commonly used)
2. **Confirm the location** — default to the TDD directory, but always ask if that's where they want it
3. **Ask about subfolders** — check if the doc should go in an existing subfolder or if a new one needs to be created

## Jira

### Spaces

The team operates across three Jira spaces (transitioning from separate Mobile/TV spaces to a unified Android space):

| Space Key | Name | Notes |
|---|---|---|
| `ANDCORE` | Android Core | **Default space** — new unified space, all Android tickets going forward |
| `ANDTV` | AndroidTV | Legacy TV space, still in use during transition |
| `ETPAND` | Android Mobile | Legacy Mobile space, still in use during transition |

### Ticket Creation Behavior

- Default to the `ANDCORE` Jira space unless otherwise specified.
- If I don't specify the issue type, ask whether it's a **Bug**, **Task**, **Story**, **Epic**, or **Spike** — unless creating tickets in bulk, in which case use context clues to determine the type.
- After every ticket is created, share the link to the ticket. For bulk creation, share a list of all links at the end.

### Ticket Templates

Only fill out required sections unless there is important information that warrants including an optional section. Do not include "(Required)" or "(Optional)" labels in ticket descriptions — just use the section header.

---

#### Spike

**Required sections:** Background, Objective, Acceptance Criteria, Outcome

**Optional sections:** References, Technical Considerations, What does success look like, Out of Scope, Dependencies, Notes

```
## Background
[Describe the context and motivation for this spike]

## Objective
[Describe what this spike aims to investigate or answer]

## Acceptance Criteria
[List the conditions that define the spike as complete]

## Outcome
[What should be produced — e.g., ticket breakdown, document, PoC]
```

---

#### Story

**Required sections:** Background, Objective, Acceptance Criteria, How to Test, References

**Optional sections:** Technical Considerations, What does success look like, Test Cases, Out of Scope, Dependencies, Notes

```
## Background
[Describe the context and motivation for this story]

## Objective
[Describe what this story aims to deliver]

## Acceptance Criteria
[List the conditions that define the story as complete]

## How to Test
[Step-by-step instructions for verifying the story]

## References
[Links, design files, screenshots, etc.]
```

---

#### Task

**Required sections:** Background, Objective

**Optional sections:** Acceptance Criteria, How to Test, References, Technical Considerations, What does success look like, Out of Scope, Dependencies, Notes

```
## Background
[Describe the context and motivation for this task]

## Objective
[Describe what this task aims to accomplish]
```

---

#### Bug

**Required sections:** Observation, Expectation, Steps to Reproduce, Reproducibility Rate, Impacted, References

**Optional sections:** Dependencies, Notes

```
## Observation
[Describe the buggy behavior that was observed]

## Expectation
[Describe the correct/expected behavior]

## Steps to Reproduce
[Step-by-step instructions to reproduce the bug]

## Reproducibility Rate
[e.g., 3/5 attempts, Always, Intermittent]

## Impacted
[Users / Crunchyroll / Both]

## References
[Screenshots, recordings, network logs, logcat logs, etc.]
```
