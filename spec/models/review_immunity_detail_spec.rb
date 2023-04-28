# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReviewImmunityDetail do
  describe "validations" do
    subject(:review_immunity_detail) { described_class.new }

    describe "#decision" do
      it "validates presence for decision" do
        expect { review_immunity_detail.valid? }.to change { review_immunity_detail.errors[:decision] }.to ["can't be blank", "is not included in the list"]
      end

      it "validates inclusion in list ['Yes', 'No']" do
        review_immunity_detail = described_class.new(decision: "Maybe")

        expect { review_immunity_detail.valid? }.to change { review_immunity_detail.errors[:decision] }.to ["is not included in the list"]
      end
    end

    describe "#decision_reason" do
      it "validates presence for decision_reason" do
        expect { review_immunity_detail.valid? }.to change { review_immunity_detail.errors[:decision_reason] }.to ["can't be blank"]
      end
    end

    describe "#summary" do
      context "when decision is yes" do
        let(:review_immunity_detail) { described_class.new(decision: "Yes") }

        it "validates presence for summary" do
          expect { review_immunity_detail.valid? }.to change { review_immunity_detail.errors[:summary] }.to ["can't be blank"]
        end
      end

      context "when decision is no" do
        let(:review_immunity_detail) { described_class.new(decision: "No") }

        it "does not validates presence for removed_reason" do
          expect { review_immunity_detail.valid? }.not_to(change { review_immunity_detail.errors[:summary] })
        end
      end
    end
  end

  describe "callbacks" do
    describe "::before_create #ensure_no_open_review_immunity_detail_response!" do
      let(:immunity_detail) { create(:immunity_detail) }

      context "when there is already an open review immunity detail response" do
        let(:new_review_immunity_detail) { create(:review_immunity_detail, immunity_detail:) }

        before { create(:review_immunity_detail, immunity_detail:) }

        it "raises an error" do
          expect do
            new_review_immunity_detail
          end.to raise_error(described_class::NotCreatableError, "Cannot create a review immunity detail response when there is already an open response")
        end
      end

      context "when there is no open review immunity detail response to be reviewed" do
        let(:new_review_immunity_detail) { create(:review_immunity_detail, immunity_detail:) }

        before { create(:review_immunity_detail, immunity_detail:, reviewed_at: Time.current) }

        it "does not raise an error" do
          expect do
            new_review_immunity_detail
          end.not_to raise_error
        end
      end
    end
  end

  describe "scopes" do
    describe ".not_accepted" do
      before do
        create(:review_immunity_detail, :accepted)
      end

      let!(:review_immunity_detail1) { create(:review_immunity_detail, accepted: false) }
      let!(:review_immunity_detail2) { create(:review_immunity_detail, accepted: false) }

      it "returns non accepted review immunity detail responses" do
        expect(described_class.not_accepted).to eq([review_immunity_detail1, review_immunity_detail2])
      end
    end

    describe ".reviewer_not_accepted" do
      before do
        create(:review_immunity_detail, accepted: false, reviewed_at: nil)
        create(:review_immunity_detail, :accepted)
      end

      let!(:review_immunity_detail) { create(:review_immunity_detail, accepted: false, reviewed_at: Time.current) }

      it "returns non accepted review immunity detail responses that has a reviewer associated" do
        expect(described_class.reviewer_not_accepted).to eq([review_immunity_detail])
      end
    end
  end
end
