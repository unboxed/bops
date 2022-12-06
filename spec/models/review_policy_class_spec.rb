# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReviewPolicyClass do
  let(:review_policy_class) { build(:review_policy_class) }

  describe "#valid?" do
    it "is true for factory" do
      expect(review_policy_class.valid?).to be(true)
    end
  end

  describe "validations" do
    subject(:validation_request) { described_class.new }

    describe "#mark" do
      it "validates presence" do
        expect { validation_request.valid? }.to change { validation_request.errors[:mark] }.to ["can't be blank"]
      end
    end

    describe "#comment" do
      it "validates presence when returning to officer" do
        validation_request.mark = :return_to_officer_with_comment

        expect { validation_request.valid? }.to change { validation_request.errors[:comment] }.to ["can't be blank"]
      end

      it "does not validates presence when accepting" do
        validation_request.mark = :accept

        expect { validation_request.valid? }.not_to change { validation_request.errors[:comment] }
      end
    end

    describe "#recommendation_not_accepted" do
      it "errors if recommendation accepted" do
        allow_any_instance_of(described_class).to receive(:last_recommendation_accepted?).and_return(true)

        expect { validation_request.valid? }.to change { validation_request.errors[:base] }.to ["You agreed with the assessor recommendation, to request any change you must change your decision on the Sign-off recommendation screen"]
      end

      it "does not errors if recommendation not accepted" do
        allow_any_instance_of(described_class).to receive(:last_recommendation_accepted?).and_return(false)

        expect { validation_request.valid? }.not_to change { validation_request.errors[:base] }
      end

      it "does not errors if recommendation has not been asked" do
        allow_any_instance_of(described_class).to receive(:last_recommendation_accepted?).and_return(nil)

        expect { validation_request.valid? }.not_to change { validation_request.errors[:base] }
      end
    end
  end

  describe "#update_required?" do
    context "when status is complete and mark is 'return to officer with comment'" do
      let(:review_policy_class) do
        create(
          :review_policy_class,
          status: :complete,
          mark: :return_to_officer_with_comment,
          comment: "comment"
        )
      end

      it "returns true" do
        expect(review_policy_class.update_required?).to be(true)
      end
    end

    context "when status is not complete and mark is 'return to officer with comment'" do
      let(:review_policy_class) do
        create(
          :review_policy_class,
          status: :not_checked_yet,
          mark: :return_to_officer_with_comment,
          comment: "comment"
        )
      end

      it "returns false" do
        expect(review_policy_class.update_required?).to be(false)
      end
    end

    context "when status is complete and mark is 'accept'" do
      let(:review_policy_class) do
        create(
          :review_policy_class,
          status: :complete,
          mark: :accept
        )
      end

      it "returns false" do
        expect(review_policy_class.update_required?).to be(false)
      end
    end
  end
end
