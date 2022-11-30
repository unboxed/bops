# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApiUser do
  it "creates api user successfully" do
    api_consumer = create(:api_user)
    expect(api_consumer).to be_valid
  end

  it "is not created without a token" do
    api_user_without_token = build(:api_user, token: nil)
    expect(api_user_without_token).not_to be_valid
  end

  it "is not created without a name" do
    api_user_without_name = build(:api_user, name: nil)
    expect(api_user_without_name).not_to be_valid
  end
end
