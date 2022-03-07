# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidationTasks::DocumentsPresenter, type: :presenter do
  include ActionView::TestCase::Behavior

  subject(:presenter) { described_class.new(view, planning_application, document) }

  let(:context) { ActionView::Base.new }
  let!(:planning_application) { create(:planning_application, :invalidated) }

  describe "#task_list_row" do
    context "when a document is invalid" do
      let!(:document) { create(:document) }
      let!(:replacement_document_validation_request) do
        create(:replacement_document_validation_request, old_document: document)
      end

      it "the task list row shows invalid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")
        expect(html).to include("Validate document - proposed-floorplan.png")
        expect(html).to include(
          "/replacement_document_validation_requests/#{replacement_document_validation_request.id}"
        )
        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--red app-task-list__task-tag\">Invalid</strong>"
        )
      end
    end

    context "when a document is valid" do
      let!(:document) { create(:document, validated: true) }

      it "the task list row shows valid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")
        expect(html).to include("Validate document - proposed-floorplan.png")
        expect(html).to include(
          "/planning_applications/#{planning_application.id}/documents/#{document.id}/edit?validate=yes"
        )
        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--green app-task-list__task-tag\">Valid</strong>"
        )
      end
    end

    context "when a document is not checked yet" do
      let!(:document) { create(:document) }

      it "the task list row shows not checked yet status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")
        expect(html).to include("Validate document - proposed-floorplan.png")
        expect(html).to include(
          "/planning_applications/#{planning_application.id}/documents/#{document.id}/edit?validate=yes"
        )
        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--grey app-task-list__task-tag\">Not checked yet</strong>"
        )
      end
    end
  end
end
