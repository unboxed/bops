# frozen_string_literal: true

require "rails_helper"

RSpec.describe Validation::OtherChangeValidationTask, type: :component do
  let(:planning_application) { create(:planning_application, :not_started) }

  let(:other_change_validation_request) do
    create(
      :other_change_validation_request,
      planning_application:,
      sequence: 1,
      state: "open"
    )
  end

  let(:task) do
    described_class.new(
      planning_application,
      request_sequence: other_change_validation_request.sequence,
      request_status: other_change_validation_request.state,
      request_id: other_change_validation_request.id
    )
  end

  it "renders 'Invalid' status" do
    expect(task.task_list_status).to be :invalid
  end

  it "renders link" do
    expect(task.task_list_link_text).to eq "View other validation request #1"
    expect(task.task_list_link).to eq "/planning_applications/#{planning_application.reference}/validation/other_change_validation_requests/#{other_change_validation_request.id}"
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
      expect(task.task_list_status).to be :updated
    end
  end
end
