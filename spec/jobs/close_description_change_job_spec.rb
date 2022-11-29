# frozen_string_literal: true

require "rails_helper"

RSpec.describe CloseDescriptionChangeJob do
  let!(:planning_application) { create(:planning_application) }

  let!(:description_change_request) do
    create(:description_change_validation_request,
           planning_application: planning_application,
           created_at: 6.business_days.ago)
  end

  it "changes the application's description" do
    expect { described_class.perform_now }.to(change { planning_application.reload.description })
  end

  it "auto-closes the change request" do
    expect { described_class.perform_now }
      .to(change { description_change_request.reload.state }.from("open").to("closed")
          .and(change { description_change_request.reload.auto_closed }.from(false).to(true)))
  end
end
