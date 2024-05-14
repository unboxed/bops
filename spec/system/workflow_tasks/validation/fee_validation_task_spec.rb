# frozen_string_literal: true

require "rails_helper"

RSpec.describe Validation::FeeValidationTask, type: :component do
  let(:task) { described_class.new(planning_application) }

  context "when planning application has valid fee" do
    let(:planning_application) do
      create(:planning_application, :not_started, valid_fee: true)
    end

    it "renders 'Valid' status" do
      expect(task.task_list_status).to be :complete
    end

    it "renders link to fee items path" do
      expect(task.task_list_link_text).to eq "Check fee"
      expect(task.task_list_link).to eq "/planning_applications/#{planning_application.id}/validation/fee_items"
    end
  end

  context "when check is not started" do
    let(:planning_application) { create(:planning_application, :not_started) }

    it "renders 'Not started' status" do
      expect(task.task_list_status).to be :not_started
    end

    it "renders link to fee items path" do
      expect(task.task_list_link_text).to eq "Check fee"
      expect(task.task_list_link).to eq "/planning_applications/#{planning_application.id}/validation/fee_items"
    end
  end

  context "when there is an open request" do
    let(:planning_application) { create(:planning_application, :not_started) }

    let!(:fee_change_validation_request) do
      create(
        :fee_change_validation_request,
        planning_application:
      )
    end

    it "renders 'Invalid' status" do
      expect(task.task_list_status).to be :invalid
    end

    it "renders link to fee items path" do
      expect(task.task_list_link_text).to eq "Check fee"
      expect(task.task_list_link).to eq "/planning_applications/#{planning_application.id}/validation/fee_change_validation_requests/#{fee_change_validation_request.id}"
    end
  end

  context "when there is a closed request" do
    let(:planning_application) { create(:planning_application, :not_started) }

    let!(:fee_change_validation_request) do
      create(
        :fee_change_validation_request,
        :closed,
        planning_application:
      )
    end

    it "renders 'Invalid' status" do
      expect(task.task_list_status).to be :updated
    end

    it "renders link to fee items path" do
      expect(task.task_list_link_text).to eq "Check fee"
      expect(task.task_list_link).to eq "/planning_applications/#{planning_application.id}/validation/fee_change_validation_requests/#{fee_change_validation_request.id}"
    end
  end
end
