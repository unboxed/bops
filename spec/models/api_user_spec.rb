# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApiUser do
  describe "#validations" do
    it "creates api user successfully" do
      api_user = create(:api_user)
      expect(api_user).to be_valid
    end

    it "generates a new client secret" do
      api_user = build(:api_user)
      api_user.save

      expect(api_user.token).not_to be_empty
    end

    it "is not created without a name" do
      api_user = build(:api_user, name: nil)
      expect(api_user).not_to be_valid
    end
  end
end
