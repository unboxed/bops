# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Swagger index file", type: :system do
  before do
    visit "/api-docs/index.html"
  end

  it "Lists all available API options for planning applications" do
    expect(page).to have_text("GET/api/v1/planning_applications/{id}")
    expect(page).to have_text("GET/api/v1/planning_applications")
    expect(page).to have_text("POST/api/v1/planning_applications")
  end

  it "Lists all available API options for validation requests" do
    expect(page).to have_text("GET/api/v1/planning_applications/{planning_application_id}/validation_requests")
    expect(page).to have_text("PATCH/api/v1/planning_applications/{planning_application_id}/description_change_validation_requests")
  end
end
