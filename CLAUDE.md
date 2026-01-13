# CLAUDE.md

Instructions for Claude Code and other LLM assistants working in this codebase.

## Project Context

Read these docs first:
- [docs/architecture.md](docs/architecture.md) - Engine structure and multi-tenant routing
- [docs/development.md](docs/development.md) - Commands, Docker setup, testing
- [docs/code-style.md](docs/code-style.md) - Linting and style guidelines
- [docs/gotchas.md](docs/gotchas.md) - Common pitfalls

## Workflow

- **Non-trivial changes:** Use [plan-first](.claude/skills/plan-first.md) before coding
- **Debugging:** See [debugging](.claude/skills/debugging.md) for investigation approach
- **Stuck?** See [when-stuck](.claude/skills/when-stuck.md)

## Session Hygiene

- Use `/clear` between unrelated tasks to reset context
- Use `.claude/SCRATCHPAD.md` for notes and reasoning during complex tasks
- Delete SCRATCHPAD.md when done

## Principles

- Follow existing BOPS patterns over inventing new ones
- Prefer small, reversible changes
- Ask before making assumptions
- Run the narrowest possible test set first
- CI failures are blockers; fix issues rather than working around checks
