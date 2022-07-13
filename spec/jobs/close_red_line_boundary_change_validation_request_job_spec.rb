# frozen_string_literal: true

require "rails_helper"

RSpec.describe CloseRedLineBoundaryChangeValidationRequestJob, type: :job do
  let!(:planning_application) { create :planning_application, boundary_geojson: nil }

  context "when over 5 business days have passed" do
    before { freeze_time }

    let!(:red_line_boundary_change_validation_request) do
      create :red_line_boundary_change_validation_request, :open,
             planning_application: planning_application,
             created_at: 6.business_days.ago
    end

    it "changes the planning application's boundary geojson" do
      expect { described_class.perform_now }.to(change { planning_application.reload.boundary_geojson }.from(planning_application.boundary_geojson).to(red_line_boundary_change_validation_request.new_geojson))
    end

    it "auto-closes the request and approves the change" do
      expect { described_class.perform_now }
        .to(change { red_line_boundary_change_validation_request.reload.state }.from("open").to("closed")
          .and(change { red_line_boundary_change_validation_request.reload.auto_closed }.from(false).to(true))
          .and(change { red_line_boundary_change_validation_request.reload.auto_closed_at }.from(nil).to(Time.current)))
    end

    it "sends an email" do
      expect { described_class.perform_now }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "adds an auto-close audit entry" do
      described_class.perform_now

      audit = red_line_boundary_change_validation_request.reload.audits.max

      expect(audit.activity_type).to eq("auto_closed")
    end
  end

  context "when less than 5 business days have passed" do
    let!(:red_line_boundary_change_validation_request) do
      create :red_line_boundary_change_validation_request, :open,
             planning_application: planning_application,
             created_at: 4.business_days.ago
    end

    it "does not change the planning application's boundary geojson" do
      expect { described_class.perform_now }.not_to(change { planning_application.reload.boundary_geojson })
    end

    it "does not auto-close the request" do
      expect { described_class.perform_now }
        .not_to(change { red_line_boundary_change_validation_request.reload.state })
    end

    it "does not send an email" do
      expect { described_class.perform_now }.not_to(change { ActionMailer::Base.deliveries.count })
    end
  end
end
