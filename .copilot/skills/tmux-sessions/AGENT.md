# Tmux Session Management — Agent Instructions

## When to Use This Skill

Use `tmux-mgr` whenever you need to:
- Run long-lived background processes (builds, servers, watchers)
- Organize parallel workstreams into named sessions
- Track what's happening across multiple terminal contexts
- Send commands to running sessions without switching context

## Quick Reference

```bash
TMX="$HOME/.copilot/skills/tmux-sessions/bin/tmux-mgr"

# Always start by checking current state
$TMX status

# Create sessions with intent documented
$TMX create <name> --project <project> --purpose "<what it's for>" --dir <path>

# Inspect a session deeply
$TMX inspect <name>

# Get structured JSON (for programmatic decisions)
$TMX list

# Annotate as work progresses
$TMX annotate <session> --note "Started gradle build"
$TMX annotate <session> --tag <tag>

# Run commands in sessions
$TMX send <session>:<window>.<pane> "command here"

# Save state before major changes
$TMX snapshot
```

## Agent Decision Framework

### Before creating a session, ask:
1. Does a session for this project/purpose already exist? (`tmux-mgr status`)
2. Should this be a new window in an existing session, or a new session?
3. What's the purpose — will it need multiple windows/panes?

### Naming conventions:
- Project-scoped: `<project>-<activity>` (e.g., `android-build`, `android-test`)
- Task-scoped: `<ticket>` (e.g., `ANDCORE-456`)
- Utility: `<tool>` (e.g., `gradle-daemon`, `adb-logcat`)

### When to snapshot:
- Before killing sessions
- At the end of a work session
- Before making structural changes to layouts

### When to annotate:
- After creating a session (purpose is set during create)
- When starting a new phase of work in that session
- When encountering something noteworthy (errors, decisions)

## State File Location

`~/.copilot/skills/tmux-sessions/state.json`

This file persists metadata even after sessions are killed (marked with `killed_at`),
allowing you to review what was done and restore sessions later.
