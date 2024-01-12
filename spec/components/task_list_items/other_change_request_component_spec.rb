# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskListItems::OtherChangeRequestComponent, type: :component do
  let(:planning_application) { create(:planning_application, :not_started) }

  let(:other_change_validation_request) do
    create(
      :other_change_validation_request,
      planning_application:,
      sequence: 1,
      state: "open"
    )
  end

  let(:component) do
    described_class.new(
      planning_application:,
      request_sequence: other_change_validation_request.sequence,
      request_status: other_change_validation_request.state,
      request_id: other_change_validation_request.id
    )
  end

  before { render_inline(component) }

  it "renders 'Invalid' status" do
    expect(page).to have_content("Invalid")
  end

  it "renders link" do
    expect(page).to have_link(
      "View other validation request #1",
      href: "/planning_applications/#{planning_application.id}/validation/other_change_validation_requests/#{other_change_validation_request.id}"
    )
  end

  context "when request is closed" do
    let(:other_change_validation_request) do
      create(
        :other_change_validation_request,
        planning_application:,
        sequence: 1,
        state: :closed,
        response: "response"
      )
    end

    it "renders 'Updated' status" do
      expect(page).to have_content("Updated")
    end
  end
end
