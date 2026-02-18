# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check site history task", type: :system do
  let(:planning_application) do
    create(:planning_application, :pre_application, :in_assessment, local_authority:)
  end

  it_behaves_like "check site history", :pre_application
end
