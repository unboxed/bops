# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidationTasks::FeeItemsPresenter, type: :presenter do
  include ActionView::TestCase::Behavior

  subject(:presenter) { described_class.new(view, planning_application) }

  let(:context) { ActionView::Base.new }
  let!(:planning_application) { create(:planning_application, :invalidated) }

  describe "#task_list_row" do
    context "when fee item is invalid" do
      let!(:other_change_validation_request) do
        create(:other_change_validation_request, :fee, planning_application: planning_application)
      end

      it "the task list row shows invalid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")
        expect(html).to include("Check fee")
        expect(html).to include(
          "/planning_applications/#{planning_application.id}/other_change_validation_requests/#{other_change_validation_request.id}"
        )
        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--red app-task-list__task-tag\">Invalid</strong>"
        )
      end
    end

    context "when fee item is valid" do
      let!(:planning_application) { create(:planning_application, :invalidated, valid_fee: true) }

      before do
        create(:other_change_validation_request, :fee, planning_application: planning_application)
      end

      it "the task list row shows valid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")
        expect(html).to include("Check fee")
        expect(html).to include(
          "/planning_applications/#{planning_application.id}/fee_items?validate_fee=yes"
        )
        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--green app-task-list__task-tag\">Valid</strong>"
        )
      end
    end

    context "when fee item is not checked yet" do
      it "the task list row shows not checked yet status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")
        expect(html).to include("Check fee")
        expect(html).to include(
          "/planning_applications/#{planning_application.id}/fee_items?validate_fee=yes"
        )
        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--grey app-task-list__task-tag\">Not checked yet</strong>"
        )
      end
    end

    context "when fee item is updated (i.e. there is a response from the applicant)" do
      let!(:other_change_validation_request) do
        create(:other_change_validation_request, :closed, :fee, planning_application: planning_application)
      end

      it "the task list row shows an updated status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")
        expect(html).to include("Check fee")
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
