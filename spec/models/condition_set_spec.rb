# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConditionSet do
  describe "#valid?" do
    let(:condition_set) { build(:condition_set) }

    it "is true for the default factory" do
      expect(condition_set.valid?).to be(true)
    end
  end

  describe "instance_methods" do
    describe "#approved_conditions" do
      let(:condition_set) { create(:condition_set) }

      let(:approved_condition) { create(:condition, condition_set:) }
      let(:eventually_approved_condition) { create(:condition, condition_set:) }
      let(:rejected_condition) { create(:condition, condition_set:) }

      before do
        create(:pre_commencement_condition_validation_request, owner: approved_condition, approved: true, state: "closed")
        create(:pre_commencement_condition_validation_request, owner: rejected_condition, approved: false, state: "closed", rejection_reason: "bad")
        create(:pre_commencement_condition_validation_request, owner: eventually_approved_condition, approved: true, state: "closed", notified_at: 1.day.ago)
        create(:pre_commencement_condition_validation_request, owner: eventually_approved_condition, approved: false, state: "closed", rejection_reason: "bad", notified_at: 2.days.ago)
      end

      it "returns conditions that have been approved" do
        expect(condition_set.approved_conditions).to include(approved_condition, eventually_approved_condition)
      end

      it "excludes conditions that have been approved but later cancelled" do
        approved_condition.update!(cancelled_at: Time.zone.today)

        expect(condition_set.approved_conditions).not_to include(approved_condition)
        expect(condition_set.approved_conditions).to include(eventually_approved_condition)
      end
    end

    describe "#confirm_pending_requests!" do
      before do
        travel_to(Time.zone.local(2024, 4, 17, 12, 30))
      end

      let(:condition_set) { create(:condition_set) }
      let(:condition1) { create(:condition, condition_set:) }
      let(:condition2) { create(:condition, condition_set:) }
      let(:condition3) { create(:condition, condition_set:) }
      let!(:request1) { create(:pre_commencement_condition_validation_request, state: "open", owner: condition1) }
      let!(:request2) { create(:pre_commencement_condition_validation_request, state: "pending", owner: condition2) }
      let!(:request3) { create(:pre_commencement_condition_validation_request, state: "pending", owner: condition3) }

      it "only pending validation requests are marked as sent and an email is sent" do
        expect {
          condition_set.confirm_pending_requests!
        }.to change {
          ActionMailer::Base.deliveries.count
        }.by(1)

        request1.reload
        expect(request1.state).to eq("open")
        expect(request1.notified_at).not_to eq(Time.zone.local(2024, 4, 17, 12, 30))

        request2.reload
        expect(request2.state).to eq("open")
        expect(request2.notified_at).to eq(Time.zone.local(2024, 4, 17, 12, 30))

        request3.reload
        expect(request3.state).to eq("open")
        expect(request3.notified_at).to eq(Time.zone.local(2024, 4, 17, 12, 30))
      end
    end
  end

  describe "on a determined application" do
    let(:planning_application) { create(:planning_application, :awaiting_determination, application_type:, local_authority:) }
    let(:local_authority) { create(:local_authority, :default) }
    let(:application_type) { create(:application_type, :planning_permission) }
    let(:condition_set) { planning_application.condition_set }

    it "has its conditions removed when refused" do
      expect(condition_set.conditions).not_to be_empty
      planning_application.decision = :refused
      planning_application.determine!
      expect(condition_set.conditions).to be_empty
    end

    it "does not have its conditions removed when granted" do
      expect(condition_set.conditions).not_to be_empty
      planning_application.decision = :granted
      planning_application.determine!
      expect(condition_set.conditions).not_to be_empty
    end
  end
end
