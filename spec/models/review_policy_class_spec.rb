# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReviewPolicyClass, type: :model do
  let(:review_policy_class) { build(:review_policy_class) }

  describe "#valid?" do
    it "is true for factory" do
      expect(review_policy_class.valid?).to eq(true)
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
  end
end
