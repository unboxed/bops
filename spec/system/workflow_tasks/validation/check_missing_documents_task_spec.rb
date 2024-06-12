# frozen_string_literal: true

require "rails_helper"

RSpec.describe Validation::CheckMissingDocumentsTask, type: :component do
  let(:planning_application) { create(:planning_application, :not_started) }

  let(:task) { described_class.new(planning_application) }

  it "renders link" do
    expect(task.task_list_link_text).to eq "Check and request documents"
    expect(task.task_list_link).to eq "/planning_applications/#{planning_application.id}/validation/documents/edit"
  end

  it "renders 'Not started' status" do
    expect(task.task_list_status).to be :not_started
  end

  context "when there is an open request" do
    before do
      create(
        :additional_document_validation_request,
        planning_application:
      )
    end

    it "renders 'Invalid' status" do
      expect(task.task_list_status).to be :awaiting_response
    end
  end

  context "when 'documents_missing' is false" do
    let(:planning_application) do
      create(:planning_application, documents_missing: false)
    end

    it "renders 'Valid' status" do
      expect(task.task_list_status).to be :complete
    end
  end
end
