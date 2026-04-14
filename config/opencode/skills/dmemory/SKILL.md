---
name: dmemory
description: Use when working in a project that stores durable, project-wide context in `./MEMORY.md`
---

# Durable Memory

## When to Use

- Project stores durable context in `./MEMORY.md`
- Need project-wide constraints or conventions from memory
- Need to decide whether new information belongs in memory or docs

Do not use for feature-specific documentation or temporary working notes.

## Quick Reference

- Read `./MEMORY.md`.
- If repo docs or startup guidance specify a different memory file, use that instead.
- If missing, create it with project overview and core conventions.
- Add only durable, project-wide facts.
- Put feature and subsystem behavior in docs or wiki.

## What Belongs In Memory

- Architecture decisions
- Hard constraints and invariants
- Naming and versioning conventions
- Project-wide operational assumptions
- Repeated user or team preferences

Do not store:
- Debugging notes
- Logs
- TODOs
- Speculation
- Secrets

## Memory Rules

- Keep entries concise and factual.
- Use stable headings.
- Update or supersede stale notes.

## Common Mistakes

- Putting feature-specific behavior in memory
- Recording temporary context in memory
- Ignoring repo-specific memory-location overrides
- Letting stale rules pile up without superseding them
- Treating memory as optional in a project that relies on it
