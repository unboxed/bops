# frozen_string_literal: true

require "rails_helper"

RSpec.describe Review do
  let(:review) { build(:review) }

  describe "#valid?" do
    it "is true for factory" do
      expect(review.valid?).to be(true)
    end
  end

  describe "validations" do
    subject(:review) { described_class.new }

    describe "#comment" do
      it "validates presence when returning to officer" do
        review.action = :rejected

        expect { review.valid? }.to change { review.errors[:comment] }.to ["can't be blank"]
      end

      it "does not validates presence when accepting" do
        review.action = :accepted

        expect { review.valid? }.not_to(change { review.errors[:comment] })
      end
    end

    describe "#decision" do
      it "does not validate presence for decision" do
        expect { review.valid? }.not_to(change { review.errors[:decision] })
      end
    end

    context "when owner is immunity detail" do
      let(:immunity_detail) { create(:immunity_detail) }
      let(:review) { described_class.new(owner: immunity_detail, specific_attributes: {review_type: "enforcement"}) }

      describe "#decision" do
        it "validates presence for decision" do
          expect { review.valid? }.to change { review.errors[:decision] }.to ["can't be blank"]
        end
      end

      describe "#decision_reason" do
        it "validates presence for decision_reason" do
          expect { review.valid? }.to change { review.errors[:decision_reason] }.to ["can't be blank"]
        end
      end

      describe "#summary" do
        context "when decision is yes" do
          let(:review) { described_class.new(specific_attributes: {decision: "Yes"}, owner: immunity_detail) }

          it "validates presence for summary" do
            expect { review.valid? }.to change { review.errors[:summary] }.to ["can't be blank"]
          end
        end

        context "when decision is no" do
          let(:review) { described_class.new(specific_attributes: {decision: "No"}, owner: immunity_detail) }

          it "does not validates presence for removed_reason" do
            expect { review.valid? }.not_to(change { review.errors[:summary] })
          end
        end
      end
    end
  end

  describe "callbacks" do
    context "when owner is immunity detail" do
      describe "::before_create #ensure_no_open_evidence_review_immunity_detail_response!" do
        let(:immunity_detail) { create(:immunity_detail) }

        context "when there is already an open evidence review immunity detail response" do
          let(:new_review_immunity_detail) { create(:review, :evidence, owner: immunity_detail) }

          before { create(:review, :evidence, owner: immunity_detail) }

          it "raises an error" do
            expect do
              new_review_immunity_detail
            end.to raise_error(described_class::NotCreatableError, "Cannot create an evidence review immunity detail response when there is already an open response")
          end
        end

        context "when there is no open evidence review immunity detail response to be reviewed" do
          let(:new_review_immunity_detail) { create(:review, :evidence, owner: immunity_detail) }

          before { create(:review, :evidence, owner: immunity_detail, reviewed_at: Time.current) }

          it "does not raise an error" do
            expect do
              new_review_immunity_detail
            end.not_to raise_error
          end
        end
      end

      describe "::before_create #ensure_no_open_enforcement_review_immunity_detail_response!" do
        let(:immunity_detail) { create(:immunity_detail) }

        context "when there is already an open enforcement review immunity detail response" do
          let(:new_review_immunity_detail) { create(:review, :enforcement, owner: immunity_detail) }

          before { create(:review, :enforcement, owner: immunity_detail) }

          it "raises an error" do
            expect do
              new_review_immunity_detail
            end.to raise_error(described_class::NotCreatableError, "Cannot create an enforcement review immunity detail response when there is already an open response")
          end
        end

        context "when there is no open enforcement review immunity detail response to be reviewed" do
          let(:new_review_immunity_detail) { create(:review, :enforcement, owner: immunity_detail) }

          before { create(:review, :enforcement, owner: immunity_detail, reviewed_at: Time.current) }

          it "does not raise an error" do
            expect do
              new_review_immunity_detail
            end.not_to raise_error
          end
        end
      end
    end
  end

  describe "scopes" do
    describe ".not_accepted" do
      before do
        create(:review, action: "accepted")
      end

      let!(:review_immunity_detail1) { create(:review, action: "rejected", comment: "bad") }
      let!(:review_immunity_detail2) { create(:review, action: "rejected", comment: "bad") }

      it "returns non accepted review immunity detail responses" do
        expect(described_class.not_accepted).to eq([review_immunity_detail1, review_immunity_detail2])
      end
    end

    describe ".reviewer_not_accepted" do
      before do
        create(:review, action: "rejected", reviewed_at: nil, comment: "bad")
        create(:review, action: "accepted")
      end

      let!(:review_immunity_detail) { create(:review, action: "rejected", reviewed_at: Time.current, comment: "bad") }

      it "returns non accepted review immunity detail responses that has a reviewer associated" do
        expect(described_class.reviewer_not_accepted).to eq([review_immunity_detail])
      end
    end
  end
end
