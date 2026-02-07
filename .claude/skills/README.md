# Skills

Reusable prompt patterns for working with BOPS. Each skill has YAML frontmatter for auto-loading.

## Guiding Principles

These apply to all skills:
- Prefer small, reversible changes
- Follow existing BOPS patterns over inventing new ones
- Ask before making assumptions
- Run the narrowest possible test set first

## Available Skills

| Skill | Use When |
|-------|----------|
| [plan-first](plan-first.md) | Starting any non-trivial task |
| [debugging](debugging.md) | Investigating unexpected behavior |
| [pr-review](pr-review.md) | Reviewing pull requests |
| [when-stuck](when-stuck.md) | Blocked or confused |
| [bops-patterns](bops-patterns.md) | BOPS-specific implementations |
| [code-patterns](code-patterns.md) | BOPS coding patterns and conventions |

## Single Source of Truth

| Concept | Lives In |
|---------|----------|
| Architecture, engines | docs/architecture.md |
| Commands, Docker, CI | docs/development.md |
| Code style, linting | docs/code-style.md |
| Common pitfalls | docs/gotchas.md |
| Engine-specific docs | engines/*/README.md |
| LLM workflow instructions | CLAUDE.md |
| How to think / work | .claude/skills/ |
| Temporary reasoning | .claude/SCRATCHPAD.md |
