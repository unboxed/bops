# frozen_string_literal: true

require "rails_helper"

RSpec.describe CloseDescriptionChangeJob, type: :job do
  let!(:planning_application) do
    create :planning_application
  end
  let!(:description_change_request) do
    create :description_change_validation_request,
           planning_application: planning_application,
           created_at: 6.business_days.ago
  end

  it "updates all required statuses" do
    expect do
      described_class.perform_now
      planning_application.reload
      description_change_request.reload
    end.to change(planning_application, :description)
      .and change(description_change_request, :state)
      .and change(description_change_request, :auto_closed)
  end
end
