---
name: dev-project-wiki
description: >-
  Use after completing a significant task — new features, models, roles,
  refactors, or integrations. Checks the project wiki for gaps or stale
  entries related to the work done, proposes targeted additions or updates,
  and writes only after user approval.
---

# Maintaining the Project Wiki

Keep `documents/wiki/` current as a side effect of development work, so agents
can read one focused document instead of exploring dozens of files.

## When to trigger

**After completing a task that changed functionality:**
- New feature, model, role, or integration
- Refactored system or renamed/restructured domain concepts
- Changed how an existing feature works (new options, new workflow steps)

**Do NOT trigger after:**
- Bug fixes, typo corrections, config changes
- Dependency bumps, test-only changes
- Purely cosmetic or formatting changes
- Work that only touched files already fully covered by existing wiki entries

## Scope discipline

This is not a documentation sprint. You are capturing knowledge you already
have from the task you just completed.

- **Only document what you touched.** Do not audit the entire wiki.
- **Do not explore code beyond your current context.** The wiki entry should
  use knowledge already in your session from the completed task. If you need
  to read 10+ new files to write an entry, skip it.
- **A missing entry is better than a shallow one.** If you lack sufficient
  context to write something an agent would actually use, say so and stop.
- **Write for an agent audience.** Schema, relationships, scopes, consumption
  points, extension steps. No prose filler, no restating what code does
  line-by-line.
- **Target: one entry should replace 10+ file reads** and be readable in
  under 2 minutes.

## Workflow

1. **Review what you just completed.** What models, features, or systems were
   involved? You already know this from the task.
2. **Read `documents/wiki/index.md`** to see the existing wiki structure.
3. **Check for gaps.** For each affected area: does a wiki entry exist? If
   yes, does it need updating based on your changes? If no, would a new entry
   meaningfully help a future agent?
4. **Propose to the user.** State what you want to add or update and what it
   would cover. Keep the proposal to 2-3 sentences. If nothing qualifies,
   say so and stop.
5. **Wait for user approval.** Do not write until confirmed.
6. **Write or update the entry** following the conventions below. Update
   parent index files as needed.

## Wiki conventions

Wiki lives at `documents/wiki/`. Structure mirrors the application namespaces.

- Every directory has an `index.md` linking to its children.
- Every page starts with a back-link: `[Back to Parent](./index.md)`.
- The root `index.md` has a flat table of contents with nested links.
- When adding a new page, update its parent `index.md` and the root
  `index.md`.

Directory structure example:
```
documents/wiki/
  index.md
  backend/
    index.md
    admins/
      index.md
      roles.md
  frontend/
    index.md
  third-party-services/
    index.md
    dropbox.md
```

## What a good wiki entry contains

- Database schema (table, columns, types) when models are involved
- Model relationships and association names
- Key methods, scopes, and class methods with their purpose
- Where the functionality is consumed (file paths + brief role)
- How to extend or modify it (step-by-step recipe)
- Business rules and constraints not obvious from code alone

## What a wiki entry must NOT contain

- Prose explanations an agent can infer from reading code
- Information already in MEMORY.md (project-wide conventions, coding standards)
- Speculative or aspirational documentation ("we might want to...")
- Multi-paragraph introductions or background context

## Red flags

If you catch yourself thinking any of these, stop:

| Thought | Action |
|---------|--------|
| "Let me also document X while I'm here" | Only document what you touched. |
| "I should explore that model more thoroughly" | Use context you already have. |
| "This entry needs a full architecture overview" | Write the minimum useful entry. |
| "Let me read 15 files to write a complete picture" | If it needs that much research, skip it. |
| "I'll just add a quick stub for now" | Stubs waste tokens on read. Skip or write properly. |
