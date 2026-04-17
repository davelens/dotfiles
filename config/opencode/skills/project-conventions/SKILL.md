---
name: project-conventions
description: Use when working in a project with shared formatting rules, operational assumptions, or superpowers file-placement conventions
---

# Development Conventions

## When to Use

- Project defines shared formatting rules
- Project defines repo-wide operational assumptions
- Project uses superpowers document-location conventions

## Quick Reference

- Blank lines must be truly empty.
- Use spaces, not tabs, unless project guidance says otherwise.
- Comments use normal sentence case, not all-caps.
- Bash section headers may use simple decorative borders.
- When commits are part of the workflow, make proper git commits per finished todo item.
- Never `git push` without asking.
- Do not write to `.claude` or `.opencode`.
- Superpowers paths:
  - brainstorms: `docs/superpowers/brainstorms`
  - specs: `docs/superpowers/specs`
  - plans: `docs/superpowers/plans`

## Common Mistakes

- Writing files in tool-specific hidden directories
- Using tabs where project conventions require spaces
- Writing all-caps comments
- Ignoring project document-location conventions
- `git push` without asking.
