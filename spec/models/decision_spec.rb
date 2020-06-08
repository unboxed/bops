# frozen_string_literal: true

require "rails_helper"

RSpec.describe Decision, type: :model do
  subject { build :decision }

  describe "statuses" do
    it "has a list of statuses" do
      expect(described_class.statuses).to eq(
        "granted" => 0, "refused" => 1
      )
    end
  end

  describe "validations" do
    it "is invalid when status is nil" do
      expect(subject).to be_invalid
      expect(subject.errors.messages[:status][0]).to include "Please select Yes or No"
    end

    it "is valid when status is granted" do
      subject.status = :granted

      expect(subject).to be_valid
    end

    it "is valid when status is refused" do
      subject.status = :refused

      expect(subject).to be_valid
    end
  end
end
