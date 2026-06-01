# Tmux Session Manager — Local Skill

A persistent tmux session organization skill for Copilot CLI agents.

## Overview

This skill provides structured tmux session management with persistent metadata.
It allows an agent to create, annotate, switch, and monitor tmux sessions while
maintaining a durable record of what each session is for and its current state.

## State File

Session metadata is stored in `~/.copilot/skills/tmux-sessions/state.json`.
This file persists across agent sessions and tracks:
- Session name, purpose, project association
- Creation time, last-accessed time
- Custom tags and notes
- Window/pane layout snapshots

## Commands

All commands are invoked via `~/.copilot/skills/tmux-sessions/bin/tmux-mgr`:

### Listing & Status

```bash
tmux-mgr status              # Quick overview: all sessions with metadata
tmux-mgr list                # JSON output of all sessions + metadata
tmux-mgr inspect <session>   # Detailed view of a single session (windows, panes, procs)
```

### Session Lifecycle

```bash
tmux-mgr create <name> [--project <project>] [--purpose <text>] [--dir <path>]
tmux-mgr kill <name>
tmux-mgr rename <old> <new>
tmux-mgr switch <name>       # Switch attached client to this session
```

### Annotation & Organization

```bash
tmux-mgr annotate <session> --purpose <text>
tmux-mgr annotate <session> --tag <tag>
tmux-mgr annotate <session> --note <text>
tmux-mgr annotate <session> --project <project>
```

### Window & Pane Management

```bash
tmux-mgr new-window <session> [--name <name>] [--cmd <command>]
tmux-mgr split <session> [--horizontal|--vertical] [--cmd <command>]
tmux-mgr send <session>[:<window>][.<pane>] <keys...>
```

### Snapshots & Recovery

```bash
tmux-mgr snapshot             # Save current layout of all sessions to state
tmux-mgr restore <session>    # Recreate session from last snapshot
```

## Agent Usage

When an agent needs to manage tmux sessions, it should:

1. Run `tmux-mgr status` to see what's running
2. Use `tmux-mgr create` with `--purpose` to document intent
3. Use `tmux-mgr send` to execute commands in specific panes
4. Use `tmux-mgr annotate` to update session metadata as work evolves
5. Run `tmux-mgr snapshot` periodically to preserve layout state

## Example Workflow

```bash
# Agent creates a dev session for Android work
tmux-mgr create android-dev --project cr-android-app --purpose "Feature development" --dir ~/Development/cr-android-app

# Agent adds a window for running gradle
tmux-mgr new-window android-dev --name build --cmd "cd ~/Development/cr-android-app"

# Agent sends a build command
tmux-mgr send android-dev:build "./gradlew assembleDebug"

# Agent annotates progress
tmux-mgr annotate android-dev --note "Build running for ANDCORE-456"

# Quick status check
tmux-mgr status
```
