# Plan: Cleanup & Push

## When to use
Codebase cleanup, removing duplicate/overengineered code, reviewing, and pushing.

## Phases

### 1. Audit
Check current state. Specifically:
- Duplicate column definitions
- Unused/dead files
- SQL compilation errors (columns that don't exist)
- Broken cross-references

### 2. Fix + Simplify
- Remove exact duplicate columns
- Remove overengineered patterns (prefer simple working code)
- Delete orphan files that reference only non-existent models/columns

### 3. Verify
- `grep` for any remaining references to deleted columns/files
- `dbt compile` or LSP diagnostics on SQL files
- Check schema YAMLs are in sync

### 4. Push
- `git add` only what changed
- `git commit -m "clean: <summary>"`
- `git push origin main`

## Principles
- Dirt cheap: minimal changes, maximum impact
- Never leave duplicate columns
- If a file references columns that don't exist, either fix or delete it
