# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClosePreCommencementConditionValidationRequestJob do
  let!(:planning_application) { create(:planning_application) }

  context "when more than 10 business days have passed" do
    let!(:pre_commencement_condition_request) do
      create(:pre_commencement_condition_validation_request,
        planning_application:,
        created_at: 11.business_days.ago)
    end

    it "auto-closes the request" do
      expect { described_class.perform_now }
        .to(change { pre_commencement_condition_request.reload.state }.from("open").to("closed")
            .and(change { pre_commencement_condition_request.reload.auto_closed }.from(false).to(true))
              .and(change { pre_commencement_condition_request.reload.approved }.from(nil).to(true)))
    end

    it "sends an email" do
      expect { described_class.perform_now }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "adds an auto-close audit entry" do
      described_class.perform_now

      audit = pre_commencement_condition_request.reload.audits.max

      expect(audit.activity_type).to eq(
        "pre_commencement_condition_validation_request_auto_closed"
      )
    end
  end

  context "when less than 10 business days have passed" do
    let!(:pre_commencement_condition_request) do
      create(:pre_commencement_condition_validation_request, :open,
        planning_application:,
        created_at: 4.business_days.ago)
    end

    it "does not auto-close the request" do
      expect { described_class.perform_now }
        .not_to(change { pre_commencement_condition_request.reload.state })
    end

    it "does not send an email" do
      expect { described_class.perform_now }.not_to(change { ActionMailer::Base.deliveries.count })
    end
  end
end
