# frozen_string_literal: true

require "rails_helper"

RSpec.describe Recommendation do
  let(:default_local_authority) { create(:local_authority, :default) }

  describe "validations" do
    subject(:recommendation) { described_class.new }

    describe "#planning_application" do
      it "validates presence" do
        expect { recommendation.valid? }.to change { recommendation.errors[:planning_application] }.to ["must exist"]
      end
    end
  end

  describe "#valid?" do
    let(:planning_application) { create(:planning_application) }
    let(:recommendation) do
      build(
        :recommendation,
        planning_application: planning_application,
        status: status,
        challenged: challenged,
        reviewer_comment: reviewer_comment
      )
    end

    let(:reviewer_comment) { "comment" }

    context "when status is 'review_complete'" do
      let(:status) { :review_complete }

      context "when challenged is true" do
        let(:challenged) { true }

        context "when reviewer has requested changes" do
          before do
            create(
              :assessment_detail,
              planning_application: planning_application,
              review_status: :complete,
              reviewer_verdict: :rejected
            )
          end

          it "returns true" do
            expect(recommendation.valid?).to be(true)
          end
        end

        context "when reviewer comment is blank" do
          let(:reviewer_comment) { nil }

          it "returns false" do
            expect(recommendation.valid?).to be(false)
          end

          it "sets error message" do
            recommendation.valid?

            expect(
              recommendation.errors.messages[:base]
            ).to contain_exactly(
              "Please include a comment for the case officer to indicate why the recommendation has been challenged."
            )
          end
        end

        context "when reviewer comment is present" do
          let(:reviewer_comment) { "qwerty" }

          it "returns true" do
            expect(recommendation.valid?).to be(true)
          end
        end
      end

      context "when challenged is false" do
        let(:challenged) { false }

        context "when reviewer has requested changes" do
          before do
            create(
              :assessment_detail,
              planning_application: planning_application,
              review_status: :complete,
              reviewer_verdict: :rejected
            )
          end

          it "returns false" do
            expect(recommendation.valid?).to be(false)
          end

          it "sets error message" do
            recommendation.valid?

            expect(recommendation.errors.messages[:challenged]).to contain_exactly(
              "You have requested officer changes, resolve these before agreeing with the recommendation"
            )
          end
        end

        context "when reviewer comment is blank" do
          let(:reviewer_comment) { nil }

          it "returns true" do
            expect(recommendation.valid?).to be(true)
          end
        end
      end
    end

    context "when status is not 'review_complete'" do
      let(:status) { :review_in_progress }

      context "when challenged is false and reviewer has requested changes" do
        let(:challenged) { false }

        before do
          create(
            :assessment_detail,
            planning_application: planning_application,
            review_status: :complete,
            reviewer_verdict: :rejected
          )
        end

        it "returns true" do
          expect(recommendation.valid?).to be(true)
        end
      end

      context "when challenged is true and reviewer comment is blank" do
        let(:challenged) { true }
        let(:reviewer_comment) { nil }

        it "returns true" do
          expect(recommendation.valid?).to be(true)
        end
      end
    end
  end

  describe "instance methods" do
    let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }
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
          recommendation.assign_attributes(
            challenged: true,
            status: :review_complete
          )

          expect { recommendation.review! }
            .to raise_error(Recommendation::ReviewRecommendationError, "Validation failed: Please include a comment for the case officer to indicate why the recommendation has been challenged.")
            .and not_change(Audit, :count)

          recommendation.reload
          expect(recommendation.reviewed_at).to be_nil
          expect(recommendation.reviewer).to be_nil
          expect(recommendation.planning_application.status).to eq("awaiting_determination")
        end
      end

      context "when there is an AASM::InvalidTransition" do
        let!(:planning_application) { create(:planning_application, :in_assessment) }

        it "raises a Recommendation::ReviewRecommendationError" do
          recommendation.assign_attributes(challenged: true, reviewer_comment: "A review")

          expect { recommendation.review! }
            .to raise_error(Recommendation::ReviewRecommendationError, "Event 'request_correction' cannot transition from 'in_assessment'.")
            .and not_change(Audit, :count)

          recommendation.reload
          expect(recommendation.reviewed_at).to be_nil
          expect(recommendation.reviewer).to be_nil
          expect(planning_application.status).to eq("in_assessment")
        end
      end
    end
  end

  describe "#submitted_and_unchallenged?" do
    let(:recommendation) do
      build(
        :recommendation,
        submitted: submitted,
        challenged: challenged
      )
    end

    context "when recommendation is not submitted" do
      let(:submitted) { false }
      let(:challenged) { false }

      it "returns false" do
        expect(recommendation.submitted_and_unchallenged?).to be(false)
      end
    end

    context "when recommendation is submitted" do
      let(:submitted) { true }

      context "when recommendation is not challenged" do
        let(:challenged) { false }

        it "returns true" do
          expect(recommendation.submitted_and_unchallenged?).to be(true)
        end
      end

      context "when recommendation is challenged" do
        let(:challenged) { true }

        it "returns true" do
          expect(recommendation.submitted_and_unchallenged?).to be(false)
        end
      end
    end
  end

  describe "#accepted?" do
    let(:recommendation) do
      build(
        :recommendation,
        status: status,
        challenged: challenged
      )
    end

    context "when recommendation is not challenged but does not have a review_complete status" do
      let(:status) { "review_in_progress" }
      let(:challenged) { false }

      it "returns false" do
        expect(recommendation.accepted?).to be(false)
      end
    end

    context "when recommendation has a review_complete status but is challenged" do
      let(:status) { "review_complete" }
      let(:challenged) { true }

      it "returns false" do
        expect(recommendation.accepted?).to be(false)
      end
    end

    context "when recommendation has a review_complete status and is not challenged" do
      let(:status) { "review_complete" }
      let(:challenged) { false }

      it "returns true" do
        expect(recommendation.accepted?).to be(true)
      end
    end
  end

  describe "#rejected?" do
    let(:recommendation) do
      build(:recommendation, challenged: challenged, status: status)
    end

    let(:challenged) { true }
    let(:status) { :review_complete }

    context "when status is 'review_complete' and challenged is true" do
      it "returns true" do
        expect(recommendation.rejected?).to be(true)
      end
    end

    context "when status is 'review_complete' and challenged is false" do
      let(:challenged) { false }

      it "returns false" do
        expect(recommendation.rejected?).to be(false)
      end
    end

    context "when status is not 'review_complete' and challenged is true" do
      let(:status) { :review_in_progress }

      it "returns false" do
        expect(recommendation.rejected?).to be(false)
      end
    end
  end
end
