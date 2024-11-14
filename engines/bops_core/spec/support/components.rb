# frozen_string_literal: true

require "view_component/test_helpers"

RSpec.shared_context "helpers" do
  let(:lookup_context) { ActionView::LookupContext.new(ActionController::Base.view_paths) }
  let(:assigns) { {} }
  let(:controller) { ActionController::Base.new }
  let(:helper) { ActionView::Base.new(lookup_context, assigns, controller) }
end

RSpec.configure do |config|
  helpers = Module.new do
    def scopes
      @scopes ||= [Capybara::Node::Simple.new(rendered_content)]
    end

    def page
      scopes.last
    end
    alias_method :element, :page

    def within(*args, **kw_args)
      new_scope = element.find(*args, **kw_args)

      begin
        scopes.push(new_scope)
        yield new_scope if block_given?
      ensure
        scopes.pop
      end
    end
  end

  config.include ViewComponent::TestHelpers, type: :component
  config.include helpers, type: :component
  config.include_context "helpers", type: :component
end
