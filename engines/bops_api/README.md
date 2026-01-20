# bops_api

REST API engine for BOPS with Swagger/OpenAPI documentation. Provides both authenticated and public endpoints.

## Quick Reference

```bash
docker compose --profile console run --rm console rspec engines/bops_api  # API specs
make api-docs                                                              # Generate docs
# View Swagger UI: http://localhost:3000/api/docs
```

## Structure

```
engines/bops_api/
├── app/controllers/bops_api/
│   ├── application_controller.rb    # Base controller with error handling
│   └── v2/
│       ├── authenticated_controller.rb  # Requires API key auth
│       ├── public_controller.rb         # No auth required
│       ├── planning_applications_controller.rb
│       └── public/                       # Public endpoints
├── swagger/v2/swagger_doc.yaml      # OpenAPI spec (manually maintained)
├── schemas/                         # JSON schemas for validation
└── spec/                            # Request specs
```

## Authentication

**Authenticated endpoints** inherit from `AuthenticatedController`:
- Require `Authorization: Bearer <api_key>` header
- Scoped to `current_local_authority` via subdomain
- Use `authenticate_api_user!` before_action

**Public endpoints** inherit from `PublicController`:
- No authentication required
- Still scoped to local authority by subdomain

## Adding a New Endpoint

1. **Choose controller type:**
   - Authenticated: inherit from `V2::AuthenticatedController`
   - Public: inherit from `V2::PublicController`

2. **Create controller:**
```ruby
# engines/bops_api/app/controllers/bops_api/v2/my_controller.rb
module BopsApi
  module V2
    class MyController < AuthenticatedController
      def index
        @items = planning_applications_scope.where(...)
        render json: serialize(@items)
      end
    end
  end
end
```

3. **Add route in `config/routes.rb`:**
```ruby
namespace :v2 do
  resources :my_resources, only: [:index]
end
```

4. **Update Swagger docs:**
   - Edit `swagger/v2/swagger_doc.yaml`
   - Add path, parameters, responses, schemas

5. **Add request spec:**
```ruby
# spec/requests/v2/my_controller_spec.rb
RSpec.describe "BopsApi::V2::MyController" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:api_user) { create(:api_user, local_authority:) }

  describe "GET /api/v2/my_resources" do
    it "returns resources" do
      get "/api/v2/my_resources",
        headers: { "Authorization" => "Bearer #{api_user.token}" }
      expect(response).to have_http_status(:ok)
    end
  end
end
```

## Swagger Documentation

Swagger docs are **manually maintained** in `swagger/v2/swagger_doc.yaml`.

```bash
# Regenerate aggregated docs
make api-docs

# View docs locally
# Start server then visit http://localhost:3000/api/docs
```

When adding endpoints:
1. Add path definition
2. Add request/response schemas
3. Test in Swagger UI

## Error Handling

Use `BopsApi::ErrorHandler` concern (included in ApplicationController):

```ruby
# Raises appropriate HTTP errors
raise ActionController::BadRequest, "Invalid parameter"
raise ActiveRecord::RecordNotFound
```

Standard error responses:
- 400 Bad Request - Invalid parameters
- 401 Unauthorized - Missing/invalid API key
- 404 Not Found - Resource doesn't exist
- 422 Unprocessable Entity - Validation failed

## Schema Validation

JSON request bodies can be validated against schemas in `schemas/`:

```ruby
class MyController < AuthenticatedController
  include SchemaValidation

  def create
    validate_schema!("my_resource")
    # params are now validated
  end
end
```

## Services Architecture

The API uses a Filter Object pattern for search/filtering logic. Filters are composable, testable in isolation, and reusable across services.

### Key Classes

- **`Filters::BaseFilter`** - Abstract base class. Subclasses implement `applicable?(params)` and `apply(scope, params)`.
- **`Sorting::Sorter`** - Handles `sortBy`/`orderBy` params. Fields use snake_case keys; column defaults to key if not specified.
- **`Application::SearchService`** - Base service that composes filters, sorting, and pagination. See also `Postsubmission::CommentsService`.

### Adding a New Filter

1. Create filter class in `app/services/bops_api/filters/` extending `BaseFilter`
2. Implement `applicable?` (when to apply) and `apply` (returns filtered scope)
3. Add to service's filters array
4. Add specs in `spec/services/filters/`

## Common Gotchas

1. **Subdomain required:** API routes are scoped by subdomain. Test requests need correct host header.

2. **Swagger is manual:** Unlike RSwag in other projects, swagger_doc.yaml is hand-written. Keep it updated.

3. **V2 only:** V1 is deprecated. All new endpoints go in `v2/` namespace.

4. **Scope queries:** Always use `planning_applications_scope` or similar to ensure local authority scoping.

5. **JSON responses:** Use `render json:` - don't return HTML from API endpoints.

6. **Inheritance for constants:** When subclassing services, use `self.class::FILTERS` or define accessor methods to ensure the subclass's constants are used.
