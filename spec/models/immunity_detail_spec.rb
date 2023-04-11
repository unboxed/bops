# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImmunityDetail do
  describe "validations" do
    let(:immunity_detail) { create(:immunity_detail, status: "") }

    it "has a valid factory" do
      expect(create(:immunity_detail)).to be_valid
    end

    it "validates presence of status" do
      expect { immunity_detail }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Status can't be blank")
    end
  end
end
