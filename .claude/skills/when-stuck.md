---
name: when-stuck
description: Use when blocked, confused, or making no progress after multiple attempts.
---

# When Stuck Playbook

**Rule:** If the same explanation or correction has been given 3 times and the output is still wrong, stop and change approach.

## 1. Clear
- `/clear` and start fresh
- Re-read the original requirement
- State the problem in one sentence

## 2. Simplify
- What's the smallest version of this that works?
- Can you hardcode values first, then generalize?
- Remove complexity until it works, then add back

## 3. Show Example
- Find similar code in the codebase
- How does an existing feature do this?
- Search engines/ and app/ for patterns

## 4. Reframe
- What would a senior Rails dev do?
- What would the GOV.UK Design System recommend?
- Is there a gem that solves this?

## 5. Isolate
- Can you reproduce in Rails console?
- Can you write a failing test first?
- What's the minimal code that triggers the issue?

## 6. Ask for Help
- Document what you tried in .claude/SCRATCHPAD.md
- Share the error message and context
- Show the minimal reproduction case
