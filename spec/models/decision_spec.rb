# frozen_string_literal: true

require "rails_helper"

RSpec.describe Decision, type: :model do
  subject(:decision) { build :decision }

  describe "statuses" do
    it "has a list of statuses" do
      expect(described_class.statuses).to eq(
        "granted" => 0, "refused" => 1,
      )
    end
  end

  describe "validations" do
    it "is invalid when status is nil" do
      expect(decision).to be_invalid
      expect(decision.errors.messages[:status][0]).to include "Please select Yes or No"
    end

    it "is valid when status is granted" do
      decision.status = :granted

      expect(decision).to be_valid
    end

    context "when user is assessor" do
      before do
        decision.user.role = :assessor
      end

      it "is valid when status is refused with public_comment" do
        decision.status = :refused
        decision.public_comment = "This is not granted."

        expect(decision).to be_valid
      end

      it "is invalid when status is refused without public_comment" do
        decision.status = :refused
        decision.public_comment = " "

        expect(decision).to be_invalid
      end
    end

    context "when user is reviewer" do
      before do
        decision.user.role = :reviewer
      end

      it "is valid when status is refused" do
        decision.status = :refused
        decision.private_comment = "This is not granted."

        expect(decision).to be_valid
      end
    end
  end
end
