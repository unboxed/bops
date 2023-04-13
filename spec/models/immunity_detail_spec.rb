# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImmunityDetail do
  describe "validations" do
    it "has a valid factory" do
      expect(create(:immunity_detail)).to be_valid
    end

    it "validates presence of status" do
      immunity_detail = build(:immunity_detail, status: "", review_status: "review_not_started")
      expect { immunity_detail.save! }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Status can't be blank")
    end

    it "validates presence of review status" do
      immunity_detail = build(:immunity_detail, status: "not_started", review_status: "")
      expect { immunity_detail.save! }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Review status can't be blank")
    end
  end
end
