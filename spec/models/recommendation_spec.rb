# frozen_string_literal: true

require "rails_helper"

RSpec.describe Recommendation, type: :model do
  let(:default_local_authority) { create(:local_authority, :default) }

  describe "validations" do
    subject(:recommendation) { described_class.new }

    describe "#planning_application" do
      it "validates presence" do
        expect { recommendation.valid? }.to change { recommendation.errors[:planning_application] }.to ["must exist"]
      end
    end
  end

  describe "instance methods" do
    let!(:reviewer) { create :user, :reviewer, local_authority: default_local_authority }
    let!(:planning_application) { create(:planning_application, :awaiting_determination, decision: "granted") }
    let(:recommendation) { create(:recommendation, planning_application: planning_application) }

    describe "#review!" do
      before do
        freeze_time
        Current.user = reviewer
      end

      context "when challenged" do
        let(:recommendation) { create(:recommendation, challenged: true, reviewer_comment: "A review", planning_application: planning_application) }

        it "reviews the recommendation and the planning application state updates to awaiting_correction" do
          expect { recommendation.review! }
            .to change(recommendation, :reviewed_at).from(nil).to(Time.current)
                                                    .and change(recommendation, :reviewer_id).from(nil).to(reviewer.id)

          expect(planning_application.status).to eq("awaiting_correction")

          expect(Audit.last).to have_attributes(
            planning_application_id: planning_application.id,
            activity_type: "challenged",
            audit_comment: "A review",
            user_id: reviewer.id
          )
        end
      end

      context "when not challenged" do
        let(:recommendation) { create(:recommendation, challenged: false, planning_application: planning_application) }

        it "reviews the recommendation and the planning application state updates to awaiting_correction" do
          expect { recommendation.review! }
            .to change(recommendation, :reviewed_at).from(nil).to(Time.current)
                                                    .and change(recommendation, :reviewer_id).from(nil).to(reviewer.id)

          expect(planning_application.status).to eq("awaiting_determination")

          expect(Audit.last).to have_attributes(
            planning_application_id: planning_application.id,
            activity_type: "approved",
            user_id: reviewer.id
          )
        end
      end

      context "when there is an ActiveRecord::ActiveRecordError" do
        it "raises a Recommendation::ReviewRecommendationError" do
          recommendation.assign_attributes(challenged: true)

          expect { recommendation.review! }
            .to raise_error(Recommendation::ReviewRecommendationError, "Validation failed: Please include a comment for the case officer to indicate why the recommendation has been challenged.")
            .and change(Audit, :count).by(0)

          recommendation.reload
          expect(recommendation.reviewed_at).to eq(nil)
          expect(recommendation.reviewer).to eq(nil)
          expect(recommendation.planning_application.status).to eq("awaiting_determination")
        end
      end

      context "when there is an AASM::InvalidTransition" do
        let!(:planning_application) { create(:planning_application, :in_assessment) }

        it "raises a Recommendation::ReviewRecommendationError" do
          recommendation.assign_attributes(challenged: true, reviewer_comment: "A review")

          expect { recommendation.review! }
            .to raise_error(Recommendation::ReviewRecommendationError, "Event 'request_correction' cannot transition from 'in_assessment'.")
            .and change(Audit, :count).by(0)

          recommendation.reload
          expect(recommendation.reviewed_at).to eq(nil)
          expect(recommendation.reviewer).to eq(nil)
          expect(planning_application.status).to eq("in_assessment")
        end
      end
    end
  end
end
