---
name: dmemory
description: >-
  Use before starting any session — This is my generic AGENTS.md.
  Maintains readable project memory in MEMORY.md.
  Contains my desired formatting rules.
---

# Generic agentic guidelines for any project

## Memory
Maintain durable project knowledge in `./MEMORY.md`.

Only record high-signal, long-lived information such as:
- Architectural decisions and rationale
- Hard constraints (compliance, platforms, invariants)
- Naming/versioning conventions
- Operational assumptions
- Repeated user/team preferences

Do NOT include:
- Temporary debugging details, logs, or TODOs
- Speculation or uncertain notes
- Secrets or credentials

**Rule of thumb:** MEMORY.md is for project-wide conventions and constraints
that apply everywhere. If the information describes how a specific feature or
system works, it belongs in the wiki instead.

Keep entries concise, factual, and organized under stable headings.
When decisions change, update or mark prior notes as superseded rather than
accumulating noise.
After completing work, consider whether new durable knowledge should be added
to MEMORY.md or whether a wiki entry is more appropriate.

### Startup
At the start of any task:
- If the caveman skill is installed, run `/caveman` to init caveman mode.
- read `./MEMORY.md` to understand persistent constraints, decisions, and
conventions before making changes or recommendations.
- If no `./MEMORY.md` file exists; create one with the basic overview and architecture. An example:
```
# MEMORY.md

## Project Overview

This is a Rails project that tracks time spent on tasks.

## Architecture

- Bootstrap 5.3.5 for UI components
- **Database**: MySQL 8.x with UTF8MB4 encoding
- **Caching/Sessions**: Redis
- **Selective Rails component loading**: ActiveStorage, ActionMailbox, and ActiveJob are excluded
- **Custom autoloading**: Business logic loaded from `lib/` directory
- **Plok Engine**: Provides CMS/admin functionality including `QueuedTask` for delayed tasks and `Plok::Search::Backend` for indexable search
- **Design documents**: `documents/design/*.md` are the single source of truth for their respective features
```

## General Formatting Rules

- **Blank lines** - Must contain only the newline character, no trailing spaces or tabs
- **Indentation** - Go files follow `gofmt` (tabs). All other files use spaces only (1 tab = 2 spaces)
- **Comments** - No all-caps. Just `// Description here`
- **Section headers in bash** - Decorative borders are allowed (e.g. `# -- section ---`)

## Operational Assumptions

- Do not save files in `.claude` or `.opencode`.
- **Git commits**: Make proper commits per finished todo item

### Superpowers
If the superpowers skill is installed:
- brainstorms go in `docs/superpowers/brainstorms`
- specs go in `docs/superpowers/specs`
- plans / design docs go in `docs/superpowers/plans`
