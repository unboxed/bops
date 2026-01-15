# BOPS Architecture Overview

BOPS (Back-Office Planning System) is a Ruby on Rails 8 application for UK local authority planning services. It is organised into a set of Rails engines with multi-tenant subdomain routing.

## Multi-Tenant Architecture

Each local authority has its own subdomain (e.g., `southwark.bops.localhost`, `lambeth.bops.localhost`). Routes and data are scoped by subdomain, with the current local authority inferred from the request.

## Engines

BOPS is organised into 11 Rails engines. Each engine groups related functionality and is mounted under a specific path.

| Engine               | Purpose                                                                            |
| -------------------- | ---------------------------------------------------------------------------------- |
| **bops_core**        | Shared helpers, routing helpers and base configuration used by the other engines.  |
| **bops_admin**       | Admin interface for managing users, application types, consultees and policy data per local authority. |
| **bops_applicants**  | Interface for applicants to respond to officer requests and for neighbours to submit comments. |
| **bops_config**      | Configuration dashboard for managing application types, local authorities and other global settings, including Sidekiq access. |
| **bops_api**         | Provides public and authenticated API endpoints with Swagger documentation.        |
| **bops_submissions** | Handles incoming submissions of application data.                                  |
| **bops_consultees**  | Allows external consultees to view an application and submit comments.             |
| **bops_reports**     | Generates reports.                                                                 |
| **bops_uploads**     | Serves and accepts file uploads via Active Storage.                                |
| **bops_enforcements**| Handles enforcement case management.                                               |
| **bops_preapps**     | Pre-application advice workflow.                                                   |

## Request Flow

Each engine is mounted inside `config/routes.rb`, which uses helpers from `BopsCore` to scope routes to the current local authority. A typical request flows:

1. Request arrives at subdomain (e.g., `southwark.bops.localhost`)
2. Router identifies the local authority from the subdomain
3. Request is routed to the appropriate engine
4. Engine controller handles the action with data scoped to that authority

## Directory Structure

```
engines/
  bops_core/          # Shared functionality
  bops_admin/         # Admin interface
  bops_api/           # API endpoints
  bops_applicants/    # Applicant interface
  bops_config/        # Global configuration
  bops_consultees/    # Consultee interface
  bops_enforcements/  # Enforcement cases
  bops_preapps/       # Pre-application advice
  bops_reports/       # Reporting
  bops_submissions/   # Submission handling
  bops_uploads/       # File uploads
```

Each engine has its own `app/`, `spec/`, and `lib/` directories following Rails engine conventions. Some engines have their own `README.md` with detailed documentation (e.g., [bops_api](../engines/bops_api/README.md)).
