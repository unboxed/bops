# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidationTasks::AdditionalDocumentsPresenter, type: :presenter do
  include ActionView::TestCase::Behavior

  subject(:presenter) { described_class.new(view, planning_application) }

  let(:context) { ActionView::Base.new }
  let!(:planning_application) { create(:planning_application, :invalidated) }

  describe "#task_list_row" do
    context "when required documents is invalid" do
      before do
        create(:additional_document_validation_request, planning_application: planning_application)
      end

      it "the task list row shows invalid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")
        expect(html).to include("Validate required documents are on application")
        expect(html).to include(
          "/planning_applications/#{planning_application.id}/validation_documents"
        )
        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--red app-task-list__task-tag\">Invalid</strong>"
        )
      end
    end

    context "when required documents is valid" do
      let!(:planning_application) { create(:planning_application, :invalidated, documents_missing: false) }

      it "the task list row shows valid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")
        expect(html).to include("Validate required documents are on application")
        expect(html).to include(
          "/planning_applications/#{planning_application.id}/validation_documents"
        )
        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--green app-task-list__task-tag\">Valid</strong>"
        )
      end
    end

    context "when required documents is not checked yet" do
      it "the task list row shows not checked yet status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")
        expect(html).to include("Validate required documents are on application")
        expect(html).to include(
          "/planning_applications/#{planning_application.id}/validation_documents"
        )
        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--grey app-task-list__task-tag\">Not checked yet</strong>"
        )
      end
    end
  end
end
