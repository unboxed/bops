# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Review validation requests task", type: :system do
  let!(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:) }

  it_behaves_like "review validation requests task", :pre_application
end
