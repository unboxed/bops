---
name: pr-review
description: Use when reviewing pull requests for correctness, security, and style.
---

# PR Review Template

Use when reviewing code changes.

```
## Summary
[What this PR does in 1-2 sentences]

## Correctness
- [ ] Logic is sound
- [ ] Edge cases handled
- [ ] Error states considered

## Security
- [ ] No SQL injection vectors
- [ ] No XSS vulnerabilities
- [ ] Authorization checks in place
- [ ] No secrets in code

## Performance
- [ ] No N+1 queries
- [ ] No unnecessary database calls
- [ ] Appropriate indexing

## Style & Rails
- [ ] Follows existing patterns and Rails conventions
- [ ] No over-engineering
- [ ] Classes/methods appropriately sized

## Testing
- [ ] Meaningful tests (not just coverage)
- [ ] Edge cases and error states covered
- [ ] Factories are clean, not duplicated

## Diff Hygiene
- [ ] Changes are scoped and intentional
- [ ] No unrelated refactors
- [ ] Deleted code is fully removed

## Questions/Concerns
- [List any issues or discussion points]
```

## BOPS-Specific Checks

- Uses GOV.UK helpers, not generic link_to with classes
- Change is in the correct engine
- Queries scoped to local authority
- Specs in correct engine's spec folder
