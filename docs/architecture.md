# BOPS Architecture Overview

BOPS is organised into a set of Rails engines. Each engine groups
related functionality and is mounted under a specific path. The engines
work together to serve the back-office planning system as well as the
public and authenticated API.

## Engines and their roles

| Engine               | Purpose                                                                            |
| -------------------- | ---------------------------------------------------------------------------------- |
| **bops_core**        | Shared helpers, routing helpers and base configuration used by the other engines.  |
| **bops_admin**       | Admin interface for managing users, application types, consultees and policy data per local authority. |
| **bops_applicants**  |  Interface for applicants to respond to officer requests and for neighbours to submit comments.                            |
| **bops_config**      | Configuration dashboard for managing application types, local authorities and other global settings, including Sidekiq access.            |
| **bops_api**         | Provides public and authenticated API endpoints with Swagger documentation.        |
| **bops_submissions** | Handles incoming submissions of application data.                                  |
| **bops_consultees**  | Allows external consultees to view an application and submit comments.             |
| **bops_reports**     | Generates reports.                                                                 |
| **bops_uploads**     | Serves and accepts file uploads via Active Storage.                                |

Each engine is mounted inside `config/routes.rb`, which uses helpers from
`BopsCore` to scope routes to the current local authority. A typical
request therefore flows from the subdomain to the appropriate engine,
then to the controller handling the requested action.
