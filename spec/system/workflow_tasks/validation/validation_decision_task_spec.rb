# frozen_string_literal: true

require "rails_helper"

RSpec.describe Validation::ValidationDecisionTask, type: :component do
  let(:planning_application) { create(:planning_application) }

  let(:task) { described_class.new(planning_application) }

  it "renders status" do
    expect(task.task_list_status).to be :valid
  end

  it "renders link" do
    expect(task.task_list_link).to eq "/planning_applications/#{planning_application.id}/validation_decision"
    expect(task.task_list_link_text).to eq "Send validation decision"
  end

  context "when application is not started" do
    let(:planning_application) { create(:planning_application, :not_started) }

    it "renders status" do
      expect(task.task_list_status).to be :not_started
    end
  end

  context "when application is invalidated" do
    let(:planning_application) { create(:planning_application, :invalidated) }

    it "renders status" do
      expect(task.task_list_status).to be :invalid
    end
  end
end
