# frozen_string_literal: true

require "rails_helper"

RSpec.describe PreCommencementConditionValidationRequest do
  include_examples "ValidationRequest", described_class, "pre_commencement_condition_validation_request"

  let!(:application_type) { create(:application_type) }

  it_behaves_like("Auditable") do
    subject { create(:pre_commencement_condition_validation_request) }
  end

  describe "validations" do
    subject(:pre_commencement_condition_validation_request) { described_class.new }

    describe "#rejection_reason" do
      it "validates presence when approved is set to false" do
        planning_application = create(:planning_application, :invalidated)
        pre_commencement_condition_validation_request = described_class.new(approved: false, planning_application:)

        expect do
          pre_commencement_condition_validation_request.valid?
        end.to change {
          pre_commencement_condition_validation_request.errors[:base]
        }.to ["Please include a comment for the case officer to indicate why the pre-commencement condition has been rejected."]
      end
    end
  end

  describe "callbacks" do
    describe "::after_create #email_and_timestamp" do
      let(:condition_set) { build(:condition_set) }

      context "when first sending requests" do
        let(:condition) { build(:condition, condition_set:) }
        let(:condition2) { build(:condition, condition_set:) }
        let(:request) { build(:pre_commencement_condition_validation_request, state: "pending", owner: condition) }
        let(:request2) { build(:pre_commencement_condition_validation_request, state: "pending", owner: condition2) }

        it "only sends one email for multiple requests" do
          # First time it sends mail
          expect { request.save }.to change { ActionMailer::Base.deliveries.count }.by(1)

          # Second time, it does not
          expect { request2.save }.to change { ActionMailer::Base.deliveries.count }.by(0)
        end
      end

      context "when sending requests again" do
        let(:condition) { build(:condition, condition_set:) }
        let(:condition2) { build(:condition, condition_set:) }
        let(:request) { build(:pre_commencement_condition_validation_request, state: "closed", owner: condition) }
        let(:request2) { build(:pre_commencement_condition_validation_request, state: "pending", owner: condition2) }

        it "sends a new email if the requests are closed" do
          expect { request2.save }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
      end

      context "when sending requests a few days later" do
        let(:condition) { build(:condition, condition_set:) }
        let(:condition2) { build(:condition, condition_set:) }
        let(:request) { build(:pre_commencement_condition_validation_request, state: "closed", owner: condition) }
        let(:request2) { build(:pre_commencement_condition_validation_request, state: "closed", owner: condition2) }

        let(:request3) { build(:pre_commencement_condition_validation_request, state: "pending", owner: condition) }
        let(:request4) { build(:pre_commencement_condition_validation_request, state: "pending", owner: condition2) }

        it "sends a new email for the first batch" do
          #  First time it sends an email
          expect { request3.save }.to change { ActionMailer::Base.deliveries.count }.by(1)

          # Second time it does not
          expect { request4.save }.to change { ActionMailer::Base.deliveries.count }.by(0)
        end
      end
    end
  end
end
