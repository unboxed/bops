---
name: code-patterns
description: BOPS coding patterns and conventions - concerns, controllers, components, and testing patterns observed in the codebase.
---

# BOPS Code Patterns

This guide captures patterns observed across the BOPS codebase. These are tendencies and preferences, not strict rules - context and judgement apply.

## General Tendencies

Based on the code reviewed, the codebase tends to:

- **Lean into Rails conventions**: Makes heavy use of concerns, engines, middleware, ActiveSupport::Notifications
- **Organize via Rails Engines**: Splits functionality into isolated engines (bops_core, bops_admin, bops_config, bops_api)
- **Favour composition**: Uses concerns (`extend ActiveSupport::Concern`) for shared behavior rather than deep inheritance
- **Be explicit about defaults**: Often uses `class_attribute` with explicit `default:` values
- **Keep controllers thin**: Business logic tends to live in services, forms, or concerns
- **Write integration-focused tests**: System specs are common, with thorough coverage of UI flows
- **Let code speak for itself**: Comments are rare - the code is typically structured to be self-explanatory

## Observed Patterns

| Category | What's typically seen | How often |
|----------|----------------------|-----------|
| **File Headers** | `# frozen_string_literal: true` at the top | Very consistent |
| **Module Structure** | Namespace matches directory path | Very consistent |
| **Concerns** | `extend ActiveSupport::Concern` with `included do` block | Very consistent |
| **Class Attributes** | `class_attribute` with `instance_writer: false`, `default:` | Frequently |
| **Controller Actions** | Wrapped in `respond_to do \|format\|` blocks | Frequently |
| **Private Methods** | `set_` prefix for finders, `build_` for constructors | Frequently |
| **Hash Syntax** | Ruby 3.1+ shorthand: `{classes:, html_attributes:}` | Often |
| **Procs/Lambdas** | Stabby lambda `->` syntax | Often |
| **Constants** | SCREAMING_SNAKE_CASE with `.freeze` | Very consistent |
| **Enums** | Rails 7+ style: `enum :status, %i[...].index_with(&:to_s)` | When applicable |
| **Error Handling** | `fail(ArgumentError, msg)` for programmer errors | Sometimes |
| **Commits** | Imperative mood, concise subjects | Very consistent |

## Common Patterns

These patterns appear frequently in the codebase. They're good defaults to follow for consistency, though exceptions exist:

1. Ruby files tend to start with `# frozen_string_literal: true`
2. Module namespacing typically matches the directory structure
3. Double-quoted strings are the norm
4. Trailing commas in arrays/hashes are avoided
5. Shared behavior usually goes in concerns with `extend ActiveSupport::Concern`
6. Controllers tend to be thin - logic lives elsewhere
7. `respond_to` format blocks are common in controller actions
8. I18n translations are used for user-facing messages
9. Mutable constants are usually frozen

## Concern Structure

A typical concern follows this shape:

```ruby
# frozen_string_literal: true

module BopsCore
  module Auditable
    extend ActiveSupport::Concern
    include OtherConcern  # includes after extend

    included do
      class_attribute :audit_payload, instance_writer: false, default: -> { {} }
    end

    module ClassMethods
      def audit(*actions, event: nil, payload: {}, **options)
        after_action(only: actions, **options) do
          default_event = [
            AUDITABLE_ACTIONS[action_name],
            controller_name.singularize
          ].join(".")

          audit(event || default_event, payload)
        end
      end
    end

    def audit(event, payload = {}, &)
      event = "#{event}.bops_audit"

      if payload.is_a?(Symbol)
        payload = send(payload)
      elsif payload.is_a?(Proc)
        payload = instance_exec(&payload)
      end

      if block_given?
        ActiveSupport::Notifications.instrument(event, payload, &)
      else
        ActiveSupport::Notifications.instrument(event, payload)
      end
    end
  end
end
```

## Controller Structure

Controllers tend to follow this pattern:

```ruby
# frozen_string_literal: true

module BopsAdmin
  class InformativesController < PolicyController
    before_action :set_informatives, only: %i[index]
    before_action :build_informative, only: %i[new create]
    before_action :set_informative, only: %i[edit update destroy]

    rescue_from Pagy::OverflowError do
      redirect_to informatives_path
    end

    def index
      respond_to do |format|
        format.html
      end
    end

    def create
      respond_to do |format|
        if @informative.save
          format.html do
            redirect_to informatives_path, notice: t(".informative_successfully_created")
          end
        else
          format.html { render :new }
        end
      end
    end

    def update
      respond_to do |format|
        if @informative.update(informative_params)
          format.html do
            redirect_to informatives_path, notice: t(".informative_successfully_updated")
          end
        else
          format.html { render :edit }
        end
      end
    end

    private

    def set_informatives
      @pagy, @informatives = pagy(current_local_authority.informatives.all_informatives(search_param), limit: 10)
    end

    def build_informative
      @informative = current_local_authority.informatives.build(informative_params)
    end

    def set_informative
      @informative = current_local_authority.informatives.find(params[:id])
    end

    def informative_params
      if action_name == "new"
        {}
      else
        params.require(:informative).permit(*informative_attributes)
      end
    end

    def informative_attributes
      %i[title text]
    end
  end
end
```

## Component Structure

ViewComponents often look like this:

```ruby
# frozen_string_literal: true

module BopsCore
  class TicketPanelComponent < GovukComponent::Base
    COLOURS = %w[grey green turquoise blue red purple pink orange yellow].freeze

    renders_one :body
    renders_one :footer

    attr_reader :id, :colour

    def initialize(colour: nil, id: nil, classes: [], html_attributes: {})
      @id = id
      @colour = colour

      super(classes:, html_attributes:)
    end

    def call
      tag.div(**html_attributes) do
        safe_join([body_wrapper, footer_wrapper].compact_blank)
      end
    end

    private

    def body_wrapper
      tag.div(body, class: "bops-ticket-panel__body")
    end

    def footer_wrapper
      tag.div(footer, class: "bops-ticket-panel__footer")
    end

    def default_attributes
      {id: id, class: ["bops-ticket-panel", colour_class]}
    end

    def colour_class
      return nil if colour.blank?

      fail(ArgumentError, colour_error_message) unless valid_colour?

      "bops-ticket-panel--#{colour}"
    end

    def valid_colour?
      colour.in?(COLOURS)
    end

    def colour_error_message
      "invalid ticket panel colour #{colour}, supported colours are #{COLOURS.to_sentence}"
    end
  end
end
```

## Model Patterns

Models sometimes use patterns like:

```ruby
# frozen_string_literal: true

class Task < ApplicationRecord
  enum :status, %i[not_started in_progress completed].index_with(&:to_s)

  belongs_to :parent, polymorphic: true
  has_many :tasks, -> { order(:position) }, as: :parent, dependent: :destroy, autosave: true

  validates :slug, :name, presence: true, strict: true

  after_initialize do
    self.slug ||= name.to_s.parameterize
    self.status ||= "not_started"
  end

  def full_slug
    @full_slug ||= parent.is_a?(Task) ? "#{parent.full_slug}/#{slug}" : slug
  end

  def to_param
    full_slug
  end
end
```

## Middleware Structure

Middleware tends to be minimal:

```ruby
# frozen_string_literal: true

module BopsCore
  module Middleware
    class LocalAuthority
      def initialize(app)
        @app = app
      end

      def call(env)
        request = ActionDispatch::Request.new(env)
        env["bops.local_authority"] = ::LocalAuthority.find_by(subdomain: request.subdomains.first)

        @app.call(env)
      end
    end
  end
end
```

## Abstract Methods

When a concern expects subclasses to implement something:

```ruby
def set_collection
  raise NotImplementedError, "#{self.class.name} needs to implement #set_collection"
end
```

---

## JavaScript Patterns

Based on controllers like `auto_refresh_controller.js` and `site_notice_controller.js`.

### Stimulus Controller Structure

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["map", "logo"]
  static values = { context: Object }

  connect() {
    this.boundCallback = this.callback.bind(this)
    window.addEventListener("event", this.boundCallback)
  }

  disconnect() {
    window.removeEventListener("event", this.boundCallback)
  }

  handleClick(event) {
    event.preventDefault()
    event.stopPropagation()
    // ...
  }

  get reference() {
    return this.contextValue.reference
  }
}
```

### Extracted Helper Functions

Complex logic tends to be extracted into pure functions outside the controller class:

```javascript
const createPDF = () => {
  const pdf = new jsPDF({
    orientation: "portrait",
    unit: "pt",
    format: "a4",
    compress: true,
  })
  return pdf
}

const setFont = (pdf, colour, size, weight) => {
  pdf.setTextColor(colour)
  pdf.setFontSize(size)
  pdf.setFont("OpenSans", "normal", weight)
}

const withGraphicsState = (pdf, block) => {
  pdf.saveGraphicsState()
  block.apply(null)
  pdf.restoreGraphicsState()
}
```

**JavaScript tendencies:**
- Static `targets` and `values` declarations at class level
- Event cleanup in `disconnect()` to prevent memory leaks
- `bind(this)` stored in instance variable for cleanup
- Try/catch for operations that might fail (localStorage, etc.)
- Pure helper functions extracted above the class
- Wrapper functions for state management (`withGraphicsState`)

---

## Naming Tendencies

| Type | Typical Pattern | Example |
|------|-----------------|---------|
| Controllers | Plural resource name | `InformativesController` |
| Controller methods | `set_` for finders, `build_` for new | `set_informative`, `build_informative` |
| Concerns | Adjective form | `Auditable`, `MagicLinkable` |
| Components | Noun + Component | `TicketPanelComponent` |
| Services | Noun + Service or descriptive | `SgidAuthenticationService`, `TaskLoader` |
| Forms | Resource + Form | `EmailForm`, `CheckReportDetailsForm` |
| Middleware | Singular noun | `BopsCore::Middleware::LocalAuthority` |

## Testing Patterns

### System Specs

System specs tend to be thorough, testing full user flows:

```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Informatives" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(user)
  end

  it "allows adding an informative" do
    visit "/admin/informatives"
    expect(page).to have_selector("h1", text: "Manage informatives")

    click_link("Add informative")
    expect(page).to have_selector("h1", text: "Add a new informative")

    # Test validation errors first
    click_button("Submit")
    expect(page).to have_selector("h2", text: "There is a problem")
    expect(page).to have_link("Title can't be blank", href: "#informative-title-field-error")

    # Then happy path
    fill_in "Title", with: "Section 106"
    fill_in "Text", with: "Section 106 needs doing"

    click_button("Submit")
    expect(page).to have_current_path("/admin/informatives")
    expect(page).to have_content("Informative successfully created")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("th:nth-child(1)", text: "Section 106")
    end
  end
end
```

### Unit Specs

Unit specs often use `context` blocks starting with "when" or "with":

```ruby
# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe BopsCore::Middleware::LocalAuthority do
  let(:local_authority) { create(:local_authority, subdomain: "royston") }
  let(:response) { [200, {"Content-Type" => "text/plain"}, %w[OK]] }
  let(:app) { double(call: response) }

  subject { described_class.new(app) }

  describe "#call" do
    context "when on a local authority subdomain" do
      let(:env) { {"HTTP_HOST" => "#{local_authority.subdomain}.bops.services"} }

      it "sets the local authority in the request hash" do
        expect {
          expect(subject.call(env)).to eq(response)
        }.to change {
          env.has_key?("bops.local_authority")
        }.from(false).to(true)

        expect(env["bops.local_authority"]).to eq(local_authority)
      end
    end
  end
end
```

### Component Specs

Component specs often use `subject!` for auto-rendering:

```ruby
# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe(BopsCore::TicketPanelComponent, type: :component) do
  context "without a colour" do
    subject! do
      render_inline(described_class.new(id: "ticket")) do |ticket|
        ticket.with_body { "This is the body" }
        ticket.with_footer { "This is the footer" }
      end
    end

    it "renders the ticket panel component" do
      within "#ticket" do
        expect(element["class"]).to eq("bops-ticket-panel")
      end
    end
  end

  described_class::COLOURS.each do |colour|
    context "with the colour: #{colour.inspect}" do
      subject! do
        render_inline(described_class.new(id: "ticket", colour: colour)) do |ticket|
          ticket.with_body { "This is the body" }
        end
      end

      it "renders with the colour class" do
        within "#ticket" do
          expect(element["class"]).to eq("bops-ticket-panel bops-ticket-panel--#{colour}")
        end
      end
    end
  end
end
```

### Testing Tendencies

- `describe`/`context`/`it` structure
- Context descriptions often start with "when" or "with"
- `let` for test data, `let!` when eager evaluation is needed
- System specs use real paths: `visit "/admin/informatives"`
- Explicit CSS selectors: `have_selector("tbody tr:nth-child(1)")`
- Error cases often tested before the happy path
- `expect { }.to change { }` for state changes

## Error Handling

A few patterns seen:

```ruby
# rescue_from for expected controller errors
rescue_from Pagy::OverflowError do
  redirect_to collection_path
end

# fail for programmer errors (invalid arguments, etc.)
def colour_class
  return nil if colour.blank?
  fail(ArgumentError, colour_error_message) unless valid_colour?
  "bops-ticket-panel--#{colour}"
end

# NotImplementedError for abstract methods
def set_collection
  raise NotImplementedError, "#{self.class.name} needs to implement #set_collection"
end

# Strict validations for things that shouldn't happen
validates :slug, :name, presence: true, strict: true
```

## Commit Message Style

Commits tend to use:

- Imperative mood: "Fix pluralisation" not "Fixed pluralisation"
- Concise subject lines
- Body explains "why" when it's not obvious

Examples from the repo:
- "Fix pluralisation on controller name"
- "Remove :only option from :verify_request callback"
- "Update postgresql client in Dockerfile"
- "Revert 'Fix dashboard pagination'"

## Code Review Prompts

When reviewing code for style consistency, consider:

- Does the file have `# frozen_string_literal: true`?
- Does the module namespacing match the file path?
- Are concerns using `extend ActiveSupport::Concern`?
- Are controllers using `respond_to` blocks?
- Are user-facing strings using I18n?
- Are mutable constants frozen?
- Do private methods follow the `set_`/`build_` convention?
- Do tests use `context "when..."` structure?
- Are strings double-quoted?
- Is nesting kept shallow with guard clauses?

## Activation Prompt

If you want to lean into this style:

```
When writing Rails code for BOPS, follow these patterns where they fit:

1. Start Ruby files with `# frozen_string_literal: true`
2. Use `extend ActiveSupport::Concern` for shared behavior
3. Structure controllers with `respond_to` format blocks
4. Use `set_` prefix for finder methods, `build_` for constructors
5. Prefer `class_attribute` with explicit defaults
6. Freeze mutable constants
7. Use double-quoted strings
8. Test with explicit CSS selectors and `context "when..."` blocks
9. Keep controllers thin - put logic in services/forms/concerns
10. Use I18n for user-facing messages

These are guidelines for consistency, not strict rules. Use judgement.
```

## Gaps in This Analysis

Areas where there wasn't enough data to draw strong conclusions:

- JavaScript patterns (limited examples)
- Database migration conventions
- Full background job implementations
- Complex ActiveRecord query patterns
- API response formatting

The patterns here are based on what was observed in the codebase. Your mileage may vary, and styles may have evolved or vary by context.
