# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidationTasks::OtherChangePresenter, type: :presenter do
  include ActionView::TestCase::Behavior

  subject(:presenter) { described_class.new(view, planning_application, other_change_validation_request) }

  let(:context) { ActionView::Base.new }
  let!(:planning_application) { create(:planning_application, :invalidated) }

  describe "#task_list_row" do
    context "when other change request is open" do
      let(:other_change_validation_request) do
        create(:other_change_validation_request, :open, planning_application: planning_application)
      end

      it "the task list row shows invalid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")
        expect(html).to include("View other validation request #1")
        expect(html).to include(
          "/planning_applications/#{planning_application.id}/other_change_validation_requests/#{other_change_validation_request.id}"
        )
        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--red app-task-list__task-tag\">Invalid</strong>"
        )
      end
    end

    context "when other change request is updated (i.e. there is a response from the applicant)" do
      let(:other_change_validation_request) do
        create(:other_change_validation_request, :closed, planning_application: planning_application)
      end

      it "the task list row shows an updated status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")
        expect(html).to include("View other validation request #1")
        expect(html).to include(
          "/planning_applications/#{planning_application.id}/other_change_validation_requests/#{other_change_validation_request.id}"
        )
        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--yellow app-task-list__task-tag\">Updated</strong>"
        )
      end
    end
  end
end
