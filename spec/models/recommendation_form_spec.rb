# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecommendationForm do
  let(:recommendation_form) { build(:recommendation_form) }

  describe "#valid?" do
    it "is true for factory" do
      expect(recommendation_form.valid?).to eq(true)
    end
  end

  describe "#save" do
    let(:recommendation) { planning_application.recommendations.build }
    let(:assessor) { create(:user, :assessor) }

    context "when status is 'assessment_complete'" do
      let(:planning_application) do
        create(
          :planning_application,
          :assessment_in_progress,
          decision: nil,
          public_comment: nil
        )
      end

      let(:recommendation_form) do
        build(
          :recommendation_form,
          recommendation: recommendation,
          decision: :granted,
          public_comment: "GDPO compliant",
          assessor_comment: "LGTM",
          assessor: assessor,
          status: :assessment_complete
        )
      end

      context "when form is valid" do
        before { recommendation_form.save }

        it "updates planning application" do
          expect(planning_application.reload).to have_attributes(
            status: "in_assessment",
            decision: "granted",
            public_comment: "GDPO compliant"
          )
        end

        it "updates recommendation" do
          expect(
            planning_application.reload.recommendation
          ).to have_attributes(
            assessor: assessor,
            assessor_comment: "LGTM"
          )
        end
      end

      context "when public comment is blank" do
        let(:recommendation_form) do
          build(
            :recommendation_form,
            recommendation: recommendation,
            decision: :granted,
            public_comment: nil,
            assessor_comment: "LGTM",
            assessor: assessor,
            status: :assessment_complete
          )
        end

        it "returns false" do
          expect(recommendation_form.save).to eq(false)
        end

        it "sets error message" do
          recommendation_form.save

          expect(
            recommendation_form.errors.messages[:public_comment]
          ).to contain_exactly(
            "Please state the reasons why this application is, or is not lawful"
          )
        end

        it "does not update planning_application" do
          recommendation_form.save

          expect(planning_application.reload).to have_attributes(
            status: "assessment_in_progress",
            decision: nil,
            public_comment: nil
          )
        end

        it "does not update recommendation" do
          expect(planning_application.reload.recommendations).to be_empty
        end
      end

      context "when decision is blank" do
        let(:recommendation_form) do
          build(
            :recommendation_form,
            recommendation: recommendation,
            decision: nil,
            public_comment: "GDPO compliant",
            assessor_comment: "LGTM",
            assessor: assessor,
            status: :assessment_complete
          )
        end

        it "returns false" do
          expect(recommendation_form.save).to eq(false)
        end

        it "sets error message" do
          recommendation_form.save

          expect(
            recommendation_form.errors.messages[:decision]
          ).to contain_exactly(
            "Please select Yes or No"
          )
        end

        it "does not update planning_application" do
          recommendation_form.save

          expect(planning_application.reload).to have_attributes(
            status: "assessment_in_progress",
            decision: nil,
            public_comment: nil
          )
        end

        it "does not update recommendation" do
          expect(planning_application.reload.recommendations).to be_empty
        end
      end
    end

    context "when status is 'assessment_in_progress'" do
      let(:planning_application) do
        create(
          :planning_application,
          :in_assessment,
          decision: nil,
          public_comment: nil
        )
      end

      let(:recommendation_form) do
        build(
          :recommendation_form,
          recommendation: recommendation,
          decision: :granted,
          public_comment: "GDPO compliant",
          assessor_comment: "LGTM",
          assessor: assessor,
          status: :assessment_in_progress
        )
      end

      before { recommendation_form.save }

      context "when form is valid" do
        it "updates planning application" do
          expect(planning_application.reload).to have_attributes(
            status: "assessment_in_progress",
            decision: "granted",
            public_comment: "GDPO compliant"
          )
        end

        it "updates recommendation" do
          expect(
            planning_application.reload.recommendation
          ).to have_attributes(
            assessor: assessor,
            assessor_comment: "LGTM"
          )
        end
      end

      context "when public comment is blank" do
        let(:recommendation_form) do
          build(
            :recommendation_form,
            recommendation: recommendation,
            decision: :granted,
            public_comment: nil,
            assessor_comment: "LGTM",
            assessor: assessor,
            status: :assessment_in_progress
          )
        end

        it "updates planning application" do
          expect(planning_application.reload).to have_attributes(
            status: "assessment_in_progress",
            decision: "granted",
            public_comment: nil
          )
        end

        it "updates recommendation" do
          expect(
            planning_application.reload.recommendation
          ).to have_attributes(
            assessor: assessor,
            assessor_comment: "LGTM"
          )
        end
      end

      context "when decision is blank" do
        let(:recommendation_form) do
          build(
            :recommendation_form,
            recommendation: recommendation,
            decision: nil,
            public_comment: "GDPO compliant",
            assessor_comment: "LGTM",
            assessor: assessor,
            status: :assessment_in_progress
          )
        end

        it "updates planning application" do
          expect(planning_application.reload).to have_attributes(
            status: "assessment_in_progress",
            decision: nil,
            public_comment: "GDPO compliant"
          )
        end

        it "updates recommendation" do
          expect(
            planning_application.reload.recommendation
          ).to have_attributes(
            assessor: assessor,
            assessor_comment: "LGTM"
          )
        end
      end
    end
  end
end
