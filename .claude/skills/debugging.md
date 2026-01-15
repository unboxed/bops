---
name: debugging
description: Use when investigating unexpected behavior or failures.
---

# Debugging Template

Use when investigating unexpected behavior.

```
## Symptom
[What's happening vs. what should happen]

## What We Know
- [Fact 1]
- [Fact 2]

## Hypotheses (ranked by likelihood)
1. [Most likely cause] - Test: [how to verify]
2. [Second possibility] - Test: [how to verify]
3. [Less likely] - Test: [how to verify]

## Quickest Validation
[Single command or check that rules out/confirms top hypothesis]

## Investigation Log
- Tried X: [result]
- Tried Y: [result]

## Stop Condition
If the top hypothesis is not confirmed after the quickest validation:
- Reassess assumptions
- Simplify reproduction
- Consider clearing context and restarting
```

## Judgment Calls

- Start with the narrowest test that could confirm/deny
- Prefer reading logs over adding debug statements
- If stuck after 3 attempts at the same fix, change approach entirely
- When in doubt, reproduce in Rails console first
