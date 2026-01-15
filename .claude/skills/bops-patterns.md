---
name: bops-patterns
description: Apply BOPS-specific Rails patterns for engines, routes, migrations, testing, and GOV.UK components.
---

# BOPS-Specific Patterns

## Engine Boundary Rule

- Do not reference models, services, or constants across engines directly
- Use service objects or public interfaces
- If unsure which engine owns logic, stop and ask
- Each engine should be independently testable

## Adding a New Route

1. Identify which engine owns the feature
2. Add route in engine's `config/routes.rb`
3. Create controller in engine's `app/controllers/`
4. Add views in engine's `app/views/`
5. Test with engine-specific specs

## Adding a Migration

1. Generate migration from within container
2. Edit for strong_migrations compliance
3. Use `safety_assured` block only for intentional unsafe operations
4. Add indexes concurrently for large tables
5. Don't remove columns in same deploy as code removal

## Testing with Subdomains

- Request specs: Host is set to `planx.bops.services` in rails_helper
- System specs: Set `Capybara.app_host` to correct subdomain

## GOV.UK Helpers

Always use GOV.UK helpers:
- `govuk_link_to` not `link_to` with classes
- `govuk_button_link_to` for button-styled links
- GOV.UK form builder for all forms

## Pattern Templates

**Service Object:**
- Initialize with domain object
- Single public `call` method
- Return value or raise specific error

**ViewComponent:**
- Initialize with required data
- Keep logic minimal
- Template in same-named `.html.erb`

**Background Job:**
- Accept IDs, not objects
- Find record at start of perform
- Handle record-not-found gracefully
