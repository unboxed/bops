# frozen_string_literal: true

require "rails_helper"

RSpec.describe PermittedDevelopmentRight do
  let!(:planning_application) { create(:planning_application) }

  describe "validations" do
    subject(:permitted_development_right) { described_class.new }

    describe "#removed_reason" do
      context "when removed" do
        let(:permitted_development_right) { create(:permitted_development_right, removed: true, removed_reason: nil) }

        it "validates presence for removed_reason" do
          expect { permitted_development_right }.to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Removed reason can't be blank"
          )
        end
      end

      context "when not removed" do
        let(:permitted_development_right) { create(:permitted_development_right, :checked) }

        it "does not validates presence for removed_reason" do
          expect { permitted_development_right }.not_to raise_error
        end
      end
    end

    describe "#status" do
      before { permitted_development_right.planning_application = planning_application }

      it "validates presence" do
        expect { permitted_development_right.valid? }.to change { permitted_development_right.errors[:status] }.to ["can't be blank"]
      end
    end

    describe "#review_status" do
      before { permitted_development_right.planning_application = planning_application }

      it "validates presence of default status" do
        expect(permitted_development_right.review_status).to eq("review_not_started")
      end
    end

    describe "#reviewer_is_present?" do
      let(:permitted_development_right) { create(:permitted_development_right, reviewer_comment: "comment") }

      it "validates that a reviewer is present when the permitted development right has been reviewed" do
        expect do
          permitted_development_right
        end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Reviewer must be present when returning to officer with a comment")
      end
    end

    describe "#planning_application_can_review_assessment" do
      context "when planning application is awaiting determination" do
        let(:planning_application) { create(:planning_application, :awaiting_determination) }

        context "when planning application has no recommendation" do
          let(:permitted_development_right) { create(:permitted_development_right, :accepted, planning_application:) }

          it "validates that planning_application can review assessment and does not raise an error" do
            expect do
              permitted_development_right
            end.not_to raise_error
          end
        end

        context "when planning application has a recommendation that is agreed by the reviewer" do
          let(:permitted_development_right) { create(:permitted_development_right, :accepted, planning_application:) }

          before { create(:recommendation, :reviewed, challenged: false, planning_application:) }

          it "validates that planning_application can review assessment and raises an error" do
            expect do
              permitted_development_right
            end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: You agreed with the assessor recommendation, to request any change you must change your decision on the Sign-off recommendation screen")
          end
        end

        context "when planning application has a recommendation that is challenged by the reviewer" do
          let(:permitted_development_right) { create(:permitted_development_right, :accepted, planning_application:) }

          before { create(:recommendation, challenged: true, planning_application:) }

          it "validates that planning_application can review assessment and does not raise an error" do
            expect do
              permitted_development_right
            end.not_to raise_error
          end
        end
      end

      context "when planning application is to be reviewed" do
        let(:planning_application) { create(:planning_application, :to_be_reviewed) }
        let(:permitted_development_right) { create(:permitted_development_right, :accepted, planning_application:) }

        before { create(:recommendation, challenged: true, planning_application:) }

        it "validates that planning_application can review assessment and does not raise an error" do
          expect do
            permitted_development_right
          end.not_to raise_error
        end
      end
    end
  end

  describe "callbacks" do
    let!(:reviewer) { create(:user, :reviewer) }

    describe "::before_update #set_status_to_be_reviewed" do
      context "when a reviewer comment has been added" do
        let(:permitted_development_right) { create(:permitted_development_right, :removed) }

        it "sets the status for the assessor to be reviewed" do
          expect do
            permitted_development_right.update!(reviewer_comment: "Comment", reviewer:)
          end.to change(permitted_development_right, :status).from("removed").to("to_be_reviewed")
        end
      end

      context "when no reviewer comment has been added" do
        let(:permitted_development_right) { create(:permitted_development_right, :removed) }

        it "does not update the status" do
          expect do
            permitted_development_right.update!(accepted: true, reviewer:)
          end.not_to change(permitted_development_right, :status).from("removed")
        end
      end
    end

    describe "::before_update #set_reviewer_edited" do
      context "when reviewer accepts but edits the reason for removing the permitted development rights" do
        let(:permitted_development_right) { create(:permitted_development_right, :removed, reviewer:) }

        it "sets reviewer edited to true" do
          expect do
            permitted_development_right.update!(removed_reason: "another reason", accepted: true)
          end.to change(permitted_development_right, :reviewer_edited).from(false).to(true)
        end
      end

      context "when reviewer accepts but does not edit the reason for removing the permitted development rights" do
        let(:permitted_development_right) { create(:permitted_development_right, :removed, reviewer:) }

        it "does not set reviewer edited to true" do
          expect do
            permitted_development_right.update!(accepted: true)
          end.not_to change(permitted_development_right, :reviewer_edited).from(false)
        end
      end
    end

    describe "::before_create #ensure_no_open_permitted_development_right_response!" do
      context "when there is already an open permitted development right response to be reviewed" do
        let(:new_permitted_development_right) { create(:permitted_development_right, planning_application:) }

        before { create(:permitted_development_right, planning_application:) }

        it "raises an error" do
          expect do
            new_permitted_development_right
          end.to raise_error(described_class::NotCreatableError, "Cannot create a permitted development right response when there is already an open response")
        end
      end

      context "when there is no open permitted development right response to be reviewed" do
        let(:permitted_development_right) { create(:permitted_development_right, :removed, reviewer:, planning_application:) }

        it "does not raise an error" do
          expect do
            permitted_development_right
          end.not_to raise_error
        end
      end
    end
  end

  describe "scopes" do
    let!(:reviewer) { create(:user, :reviewer) }

    describe ".with_reviewer_comment" do
      before do
        create(:permitted_development_right, accepted: false, reviewer_comment: nil)
        create(:permitted_development_right, accepted: true)
      end

      let!(:permitted_development_right) { create(:permitted_development_right, reviewer_comment: "comment", reviewer:) }

      it "returns permitted development rights where there is a review comment" do
        expect(described_class.with_reviewer_comment).to eq([permitted_development_right])
      end
    end

    describe ".returned" do
      before do
        create(:permitted_development_right, accepted: false, reviewer_comment: nil)
        create(:permitted_development_right, accepted: true)
      end

      let!(:permitted_development_right) { create(:permitted_development_right, accepted: false, reviewer_comment: "comment", reviewer:) }

      it "returns rejected permitted development right responses" do
        expect(described_class.returned).to eq([permitted_development_right])
      end
    end
  end

  describe "#update_required?" do
    context "when review is complete and accepted is false" do
      let(:permitted_development_right) do
        build(
          :permitted_development_right,
          review_status: :review_complete,
          accepted: false
        )
      end

      it "returns true" do
        expect(permitted_development_right.update_required?).to be(true)
      end
    end

    context "when review is complete and accepted is true" do
      let(:permitted_development_right) do
        build(
          :permitted_development_right,
          review_status: :review_complete,
          accepted: true
        )
      end

      it "returns false" do
        expect(permitted_development_right.update_required?).to be(false)
      end
    end

    context "when review not complete and accepted is false" do
      let(:permitted_development_right) do
        build(
          :permitted_development_right,
          review_status: :review_in_progress,
          accepted: false
        )
      end

      it "returns false" do
        expect(permitted_development_right.update_required?).to be(false)
      end
    end
  end

  describe "#review_started?" do
    context "when review_status is 'review_not_started'" do
      let(:permitted_development_right) do
        build(:permitted_development_right, review_status: :review_not_started)
      end

      it "returns false" do
        expect(permitted_development_right.review_started?).to be(false)
      end
    end

    context "when review_status is 'review_in_progress'" do
      let(:permitted_development_right) do
        build(:permitted_development_right, review_status: :review_in_progress)
      end

      it "returns true" do
        expect(permitted_development_right.review_started?).to be(true)
      end
    end

    context "when review_status is 'review_complete'" do
      let(:permitted_development_right) do
        build(:permitted_development_right, review_status: :review_complete)
      end

      it "returns true" do
        expect(permitted_development_right.review_started?).to be(true)
      end
    end
  end
end
