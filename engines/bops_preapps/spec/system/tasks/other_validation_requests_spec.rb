# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Other validation requests task", type: :system do
  let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:) }

  it_behaves_like "other validation requests task", :pre_application
end
