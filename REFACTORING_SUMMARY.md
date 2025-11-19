# PlanningApplicationsController Refactoring Summary

## Overview
Refactored the `PlanningApplicationsController` to follow RESTful principles by extracting non-RESTful actions into dedicated nested resource controllers.

## Non-RESTful Actions Identified and Extracted

### 1. Validation Actions → `PlanningApplications::ValidationsController`
- **Old Route**: `GET /planning_applications/:reference/confirm_validation`
  - **New Route**: `GET /planning_applications/:reference/validation`
  - **Action**: `show` (displays validation confirmation page)

- **Old Route**: `PATCH /planning_applications/:reference/validate`
  - **New Route**: `POST /planning_applications/:reference/validation`
  - **Action**: `create` (validates the planning application)

- **Old Route**: `PATCH /planning_applications/:reference/invalidate`
  - **New Route**: `DELETE /planning_applications/:reference/validation`
  - **Action**: `destroy` (invalidates the planning application)

### 2. Recommendation Actions → `PlanningApplications::RecommendationsController`
- **Old Route**: `GET /planning_applications/:reference/submit_recommendation`
  - **New Route**: `GET /planning_applications/:reference/recommendation/new`
  - **Action**: `new` (shows recommendation submission form)

- **Old Route**: `GET /planning_applications/:reference/view_recommendation`
  - **New Route**: `GET /planning_applications/:reference/recommendation`
  - **Action**: `show` (displays submitted recommendation)

- **Old Route**: `PATCH /planning_applications/:reference/submit`
  - **New Route**: `POST /planning_applications/:reference/recommendation`
  - **Action**: `create` (submits the recommendation)

- **Old Route**: `PATCH /planning_applications/:reference/withdraw_recommendation`
  - **New Route**: `DELETE /planning_applications/:reference/recommendation`
  - **Action**: `destroy` (withdraws the recommendation)

### 3. Publication Actions → `PlanningApplications::PublicationsController`
- **Old Route**: `GET /planning_applications/:reference/make_public`
  - **New Route**: `GET /planning_applications/:reference/publication/new`
  - **Action**: `new` (shows make public form)

- **Old Route**: `GET /planning_applications/:reference/publish`
  - **New Route**: `GET /planning_applications/:reference/publication`
  - **Action**: `show` (shows publish page with decision notice)

- **Old Route**: `PATCH /planning_applications/:reference/determine`
  - **New Route**: `POST /planning_applications/:reference/publication`
  - **Action**: `create` (determines/publishes the planning application)

### 4. Public Comment Actions → `PlanningApplications::PublicCommentsController`
- **Old Route**: `GET /planning_applications/:reference/edit_public_comment`
  - **New Route**: `GET /planning_applications/:reference/public_comment/edit`
  - **Action**: `edit` (shows public comment edit form)

- **New Route**: `PATCH /planning_applications/:reference/public_comment`
  - **Action**: `update` (updates the public comment)

## Files Created

### Controllers
1. `/app/controllers/planning_applications/validations_controller.rb`
2. `/app/controllers/planning_applications/recommendations_controller.rb`
3. `/app/controllers/planning_applications/publications_controller.rb`
4. `/app/controllers/planning_applications/public_comments_controller.rb`

### Views (Created in new nested directories)
1. `/app/views/planning_applications/validations/show.html.erb`
2. `/app/views/planning_applications/recommendations/new.html.erb`
3. `/app/views/planning_applications/recommendations/show.html.erb`
4. `/app/views/planning_applications/publications/new.html.erb`
5. `/app/views/planning_applications/publications/show.html.erb`
6. `/app/views/planning_applications/public_comments/edit.html.erb`

## Files Deleted

### Old View Files (Replaced by nested directory structure)
1. `/app/views/planning_applications/confirm_validation.html.erb` → moved to `validations/show.html.erb`
2. `/app/views/planning_applications/submit_recommendation.html.erb` → moved to `recommendations/new.html.erb`
3. `/app/views/planning_applications/view_recommendation.html.erb` → moved to `recommendations/show.html.erb`
4. `/app/views/planning_applications/make_public.html.erb` → moved to `publications/new.html.erb`
5. `/app/views/planning_applications/publish.html.erb` → moved to `publications/show.html.erb`
6. `/app/views/planning_applications/edit_public_comment.html.erb` → moved to `public_comments/edit.html.erb`

## Files Modified

### Controllers
- `/app/controllers/planning_applications_controller.rb`
  - Removed non-RESTful actions: `confirm_validation`, `validate`, `invalidate`, `edit_public_comment`, `submit_recommendation`, `view_recommendation`, `withdraw_recommendation`, `submit`, `publish`, `make_public`, `determine`
  - Removed related before_action filters and private methods
  - Kept only RESTful actions: `index`, `show`, `new`, `edit`, `create`, `update`
  - Kept read-only member routes: `decision_notice`, `supply_documents`

### Routes
- `/config/routes/bops.rb`
  - Replaced non-RESTful member routes with nested singleton resources:
    ```ruby
    resource :validation, only: %i[show create destroy], controller: "planning_applications/validations"
    resource :recommendation, only: %i[new show create destroy], controller: "planning_applications/recommendations"
    resource :publication, only: %i[new show create], controller: "planning_applications/publications"
    resource :public_comment, only: %i[edit update], controller: "planning_applications/public_comments"
    ```

### Views
Updated all view files to use new route helpers:
- Forms now use appropriate HTTP methods (POST for create, DELETE for destroy, PATCH for update)
- Route helper calls updated throughout the application

### Specs
- Updated all system specs to use new routes
- Path helper references updated across all spec files

### Translations
- `/config/locales/en.yml`
  - Added nested translation keys for new controllers:
    - `planning_applications.validations.*`
    - `planning_applications.recommendations.*`
    - `planning_applications.publications.*`
    - `planning_applications.public_comments.*`

## Route Helper Changes

| Old Helper | New Helper | HTTP Method |
|------------|------------|-------------|
| `confirm_validation_planning_application_path` | `planning_application_validation_path` | GET |
| `validate_planning_application_path` | `planning_application_validation_path` | POST |
| `invalidate_planning_application_path` | `planning_application_validation_path` | DELETE |
| `submit_recommendation_planning_application_path` | `new_planning_application_recommendation_path` | GET |
| `view_recommendation_planning_application_path` | `planning_application_recommendation_path` | GET |
| `submit_planning_application_path` | `planning_application_recommendation_path` | POST |
| `withdraw_recommendation_planning_application_path` | `planning_application_recommendation_path` | DELETE |
| `make_public_planning_application_path` | `new_planning_application_publication_path` | GET |
| `publish_planning_application_path` | `planning_application_publication_path` | GET |
| `determine_planning_application_path` | `planning_application_publication_path` | POST |
| `edit_public_comment_planning_application_path` | `edit_planning_application_public_comment_path` | GET |

## Benefits of This Refactoring

1. **RESTful Design**: All controllers now follow RESTful conventions with standard CRUD actions
2. **Single Responsibility**: Each controller handles a specific resource lifecycle
3. **Improved Maintainability**: Smaller, focused controllers are easier to understand and modify
4. **Consistent Routing**: Standard Rails resource routing makes the API more predictable
5. **Better Separation of Concerns**: Validation, recommendation, publication, and comment editing are now separate concerns
6. **Cleaner Controller**: Main `PlanningApplicationsController` is now focused on basic CRUD operations
