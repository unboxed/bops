# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check and request documents task", type: :system do
  let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:) }

  it_behaves_like "check and request documents task", :pre_application
end
