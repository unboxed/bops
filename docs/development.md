# Development Guide

This guide covers day-to-day development commands and workflows for BOPS.

## Prerequisites

- Docker and Docker Compose
- For local development without Docker: PostgreSQL with PostGIS extension

## Quick Reference

Commands below use Docker Compose, which is the recommended dev environment. If you have local Ruby and PostgreSQL with PostGIS, you can run commands directly with `bundle exec`.

### Running Specs

```bash
# All specs
docker compose --profile console run --rm console rspec

# Engine specs
docker compose --profile console run --rm console rspec engines/bops_core

# Single file
docker compose --profile console run --rm console rspec spec/path_spec.rb

# Single example (by line number)
docker compose --profile console run --rm console rspec spec/path_spec.rb:42
```

### Makefile Commands

```bash
make cucumber           # Run Cucumber tests
make lint               # Run all linters
make lint-auto-correct  # Auto-fix lint issues
make console            # Rails console
make prompt             # Shell in container
make migrate            # Run database migrations
make api-docs           # Generate API documentation
```

### Building and Running

```bash
# Build containers (first time or after Dockerfile changes)
docker compose build

# Start the application
docker-compose up

# Database setup (inside container)
make prompt
bin/rails db:setup

# Asset compilation (if needed)
yarn install
bin/rails assets:precompile
```

## Subdomains

BOPS uses subdomain-based multi-tenancy. Each local authority has its own subdomain:

```
http://southwark.bops.localhost:3000/
http://lambeth.bops.localhost:3000/
http://buckinghamshire.bops.localhost:3000/
```

## Testing

### Test Subdomain Setup

- Request specs use `planx.bops.services` as the host
- System specs require correct subdomain configuration
- Each engine has its own `spec/` directory

### Running Engine Tests

```bash
docker compose --profile console run --rm console rspec engines/bops_core
docker compose --profile console run --rm console rspec engines/bops_admin
# etc.
```

## CI/CD

GitHub Actions runs on push and pull requests:

- **Linters:** RuboCop, Biome, Prettier, ERB Lint, Brakeman
- **Tests:** RSpec (parallelized across matrix jobs), Cucumber
- **Builds:** Docker image builds

Production deploys via ECS on release tags.

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `NOTIFY_API_KEY` | GOV.UK Notify API key (use mock value locally) |
| `OS_VECTOR_TILES_API_KEY` | OS Maps API key (from AWS Parameter Store) |
| `OTP_SECRET_ENCRYPTION_KEY` | Required for 2FA in development |

See the [BOPS Terraform repo](https://github.com/unboxed/bops-terraform) for infrastructure details.
