# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiUser, type: :model do
  it "should create api user successfully" do
    api_consumer = create(:api_user)
    expect(api_consumer).to be_valid
  end

  it "should not be created without a token" do
    api_user_without_token = build(:api_user, token: nil)
    expect(api_user_without_token).to_not be_valid
  end

  it "should not be created without a name" do
    api_user_without_name = build(:api_user, name: nil)
    expect(api_user_without_name).to_not be_valid
  end
end
