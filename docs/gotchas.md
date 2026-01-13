# Common Gotchas

Things that commonly trip up developers new to BOPS.

## Engine Isolation

BOPS is organized as 11 Rails engines. Each engine has its own:

- `spec/` directory for tests
- Routes mounted under specific paths
- Models and controllers scoped to its functionality

When running specs, target the specific engine:

```bash
docker compose --profile console run --rm console rspec engines/bops_core
docker compose --profile console run --rm console rspec engines/bops_admin
```

## Test Subdomain Configuration

- **Request specs:** Use `planx.bops.services` as the host
- **System specs:** Require correct subdomain setup for the local authority being tested

## Migrations

BOPS has 600+ existing migrations. Rules:

1. **Never modify old migrations** - Create new migrations instead
2. **Use strong_migrations patterns** for safe deployments
3. **Test migrations** both up and down

## PostGIS Requirement

The database requires the PostGIS extension for geospatial features. If you see errors about missing spatial functions, ensure PostGIS is properly installed and enabled.

## GOV.UK Notify

Email and SMS are sent via [GOV.UK Notify](https://www.notifications.service.gov.uk/), not ActionMailer directly.

- Set `NOTIFY_API_KEY` environment variable (use mock value for local development)
- Templates are managed in the GOV.UK Notify dashboard
- See `app/mailers/` for integration patterns

## 2FA in Development

To enable 2FA locally:

1. Set `OTP_SECRET_ENCRYPTION_KEY` and `NOTIFY_API_KEY` (from 1password)
2. Set `otp_required_for_login: true` on the user record
3. Use an authenticator app to complete login

## Maps

BOPS uses an [OpenLayers-powered Web Component](https://github.com/theopensystemslab/map) from Open Systems Lab. Set `OS_VECTOR_TILES_API_KEY` in `.env` for full map functionality (value in AWS Parameter Store).

## Stimulus Controllers

After adding a new Stimulus controller, run:

```bash
./bin/rails stimulus:manifest:update
```

Or create controllers with the generator:

```bash
./bin/rails generate stimulus controllerName
```
