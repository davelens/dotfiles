---
name: searching-activecollab-history
description: Use when trying to recover rationale for undocumented code, find historical context for decisions, or search ActiveCollab project management data by topic and time period
---

# Searching ActiveCollab History

## Overview

Interrogate a local SQLite cache of ActiveCollab data to recover intent behind code changes. Useful for code archaeology when commits lack context and the reasoning lives in task descriptions, comments, or time record summaries.

## When to Use

- Undocumented code needs rationale and git history is insufficient
- Need to find tasks, discussions, or time entries related to a topic within a date range
- Investigating why a feature was built, changed, or removed

Do not use for live API queries. This searches a local read-only cache only.

## Database

**Path:** `/home/davelens/.cache/ac-tui/ac-tui-167099.db`

**Always open read-only:**
```bash
sqlite3 "file:///home/davelens/.cache/ac-tui/ac-tui-167099.db?mode=ro"
```

## Schema Quick Reference

| Table | Key columns | Date format |
|-------|------------|-------------|
| `tasks` | id, project_id, name, body, created_on, updated_on | Unix timestamp |
| `comments` | id, task_id, author_name, body, created_on | Unix timestamp |
| `time_records` | id, task_id, user_id, value, date, summary | ISO date `YYYY-MM-DD` |
| `subtasks` | id, task_id, name, is_completed | -- |
| `projects` | id, name | -- |
| `task_lists` | id, project_id, name | -- |
| `users` | id, email, name | -- |
| `labels` | id, name | -- |

**FTS5 indexes exist on:**
- `tasks_fts` (name, body)
- `comments_fts` (body)

## Workflow

1. **Identify the target project.** Always start by listing projects and confirming which one to search. Ask the user if it is not obvious from context.

```sql
SELECT id, name FROM projects ORDER BY name;
```

2. **Search tasks with FTS**, scoped to the project. Use a wide date range initially.
3. **Search comments with FTS**, scoped via task -> project join.
4. **Narrow.** Once you find relevant tasks, pull full context (body + comments + subtasks).
5. **Cross-reference time records.** Time entries often have short summaries that confirm what was worked on and when.
6. **Synthesize.** State what you found, the likely rationale, and your confidence level. Be explicit about gaps (e.g., "no comments on this task" or "task body is empty").

## Query Patterns

All queries below include a `project_id` filter. Replace `?` with the target project ID from step 1.

### Full-text search on tasks (preferred for keyword/topic matching)

```sql
SELECT t.id, t.name,
       datetime(t.created_on, 'unixepoch', 'localtime') AS created,
       t.body
FROM tasks_fts fts
JOIN tasks t ON t.rowid = fts.rowid
WHERE tasks_fts MATCH 'search terms here'
  AND t.project_id = ?
  AND t.created_on BETWEEN unixepoch('2024-01-01') AND unixepoch('2024-12-31')
ORDER BY t.created_on;
```

### Full-text search on comments

```sql
SELECT c.id, c.author_name,
       datetime(c.created_on, 'unixepoch', 'localtime') AS created,
       c.body,
       t.name AS task_name
FROM comments_fts fts
JOIN comments c ON c.rowid = fts.rowid
JOIN tasks t ON t.id = c.task_id
WHERE comments_fts MATCH 'search terms here'
  AND t.project_id = ?
  AND c.created_on BETWEEN unixepoch('2024-01-01') AND unixepoch('2024-12-31')
ORDER BY c.created_on;
```

### Time records by date range and keyword

```sql
SELECT tr.date, tr.value, tr.summary,
       t.name AS task_name
FROM time_records tr
JOIN tasks t ON t.id = tr.task_id
WHERE t.project_id = ?
  AND tr.date BETWEEN '2024-01-01' AND '2024-12-31'
  AND tr.summary LIKE '%keyword%'
ORDER BY tr.date;
```

### Retrieve full context for a task (once you have a task ID)

```sql
SELECT t.name, t.body,
       datetime(t.created_on, 'unixepoch', 'localtime') AS created,
       tl.name AS task_list
FROM tasks t
LEFT JOIN task_lists tl ON tl.id = t.task_list_id
WHERE t.id = ?;

SELECT author_name, body,
       datetime(created_on, 'unixepoch', 'localtime') AS created
FROM comments WHERE task_id = ? ORDER BY created_on;

SELECT name, is_completed FROM subtasks WHERE task_id = ?;
```

## FTS5 Query Syntax

- Simple terms: `MATCH 'oauth'`
- Phrases: `MATCH '"access token"'`
- OR: `MATCH 'oauth OR authentication'`
- AND (implicit): `MATCH 'oauth token'` (both must appear)
- Prefix: `MATCH 'auth*'`
- NOT: `MATCH 'oauth NOT google'`

## Common Mistakes

- Searching across all projects instead of scoping to a specific one
- Forgetting `unixepoch()` conversion when filtering tasks/comments by date
- Using LIKE instead of FTS for keyword searches (slower, misses word boundaries)
- Treating time_records.date as a Unix timestamp (it is ISO `YYYY-MM-DD`)
- Drawing conclusions from task names alone without reading body and comments
