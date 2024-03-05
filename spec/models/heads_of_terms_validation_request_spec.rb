# frozen_string_literal: true

require "rails_helper"

RSpec.describe HeadsOfTermsValidationRequest do
  include ActionDispatch::TestProcess::FixtureFile

  include_examples "ValidationRequest", described_class, "heads_of_terms_validation_request"

  it_behaves_like("Auditable") do
    subject { create(:heads_of_terms_validation_request) }
  end

  describe "validations" do
    subject(:request) { build(:heads_of_terms_validation_request) }

    it "has a valid factory" do
      expect(request).to be_valid
    end

    describe "when another request exists" do
      let(:other_request) do
        build(
          :heads_of_terms_validation_request,
          planning_application: request.planning_application,
          owner: request.owner
        )
      end

      it "is not valid" do
        request.save

        expect do
          other_request.valid?
        end.to change {
          other_request.errors[:base]
        }.to ["An open request already exists for this term."]
      end
    end
  end

  describe "callbacks" do
    describe "::after_create #email_and_timestamp" do
      let(:heads_of_term) { build(:heads_of_term) }

      context "when first sending requests" do
        let(:term) { build(:term, heads_of_term:) }
        let(:term2) { build(:term, heads_of_term:) }
        let(:request) { build(:heads_of_terms_validation_request, state: "pending", owner: term) }
        let(:request2) { build(:heads_of_terms_validation_request, state: "pending", owner: term2) }

        it "only sends one email for multiple requests" do
          # First time it sends mail
          expect { request.save }.to change { ActionMailer::Base.deliveries.count }.by(1)

          # Second time, it does not
          expect { request2.save }.to change { ActionMailer::Base.deliveries.count }.by(0)
        end
      end

      context "when sending requests again" do
        let(:term) { build(:term, heads_of_term:) }
        let(:term2) { build(:term, heads_of_term:) }
        let(:request) { build(:heads_of_terms_validation_request, state: "closed", owner: term) }
        let(:request2) { build(:heads_of_terms_validation_request, state: "pending", owner: term2) }

        it "sends a new email if the requests are closed" do
          expect { request2.save }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
      end

      context "when sending requests a few days later" do
        let(:term) { build(:term, heads_of_term:) }
        let(:term2) { build(:term, heads_of_term:) }
        let(:request) { build(:heads_of_terms_validation_request, state: "closed", owner: term, notified_at: 2.business_days.ago) }
        let(:request2) { build(:heads_of_terms_validation_request, state: "closed", owner: term2, notified_at: 2.business_days.ago) }

        let(:request3) { build(:heads_of_terms_validation_request, state: "pending", owner: term) }
        let(:request4) { build(:heads_of_terms_validation_request, state: "pending", owner: term2) }

        it "sends a new email for the first batch" do
          #  First time it sends an email
          expect { request3.save }.to change { ActionMailer::Base.deliveries.count }.by(1)

          # Second time it does not
          expect { request4.save }.to change { ActionMailer::Base.deliveries.count }.by(0)
        end
      end
    end
  end
end
