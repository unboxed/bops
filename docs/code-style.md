# Code Style Guide

BOPS enforces consistent code style through automated linting. All code must pass CI checks before merging.

## Ruby

- **Linter:** StandardRB (via RuboCop)
- **Magic comment:** Add `# frozen_string_literal: true` to all Ruby files

## JavaScript

- **Linter:** Biome
- **Indentation:** 2 spaces
- **Semicolons:** Only as needed (ASI-safe)

## Templates

- **Linter:** ERB Lint
- **Framework:** Follow GOV.UK Design System patterns

## GOV.UK Helpers

BOPS has a custom RuboCop cop that enforces GOV.UK-specific link helpers:

```ruby
# Bad - generic Rails helper with GOV.UK classes
link_to "View application", application_path, class: "govuk-link"

# Good - use GOV.UK helpers
govuk_link_to "View application", application_path

# Bad
link_to "Submit", submit_path, class: "govuk-button"

# Good
govuk_button_link_to "Submit", submit_path
```

## ViewComponents

- **Shared components:** `engines/bops_core/app/components/` - reusable across all engines
- **Engine-specific components:** `engines/<engine>/app/components/` - for that engine only

Only create new components when the GOV.UK Design System library doesn't meet your needs.

**Before creating a component:**
- Check if GOV.UK components or helpers already solve the problem
- Discuss with the team if uncertain - not all existing components are good patterns to follow

**When creating components:**
- Components must be accessible by design
- Include specs alongside the component

## Forms

Use the [GOV.UK Ruby on Rails Form Builder gem](https://govuk-form-builder.netlify.app) for form markup. See `app/views/users/_form.html.erb` for a simple example.

## Running Linters

```bash
# All linters
make lint

# Auto-fix where possible
make lint-auto-correct
```

## Security

- **Brakeman:** Static analysis for security vulnerabilities runs in CI
- Security issues are blockers and must be resolved before merge
