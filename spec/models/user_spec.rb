# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  it "should create user with email and password" do
    assessor = create(:user, :assessor)
    expect(assessor).to be_valid
  end

  it "should create user with manager role" do
    reviewer = create(:user, :reviewer)
    expect(reviewer).to be_valid
  end

  it "should create user with admin role" do
    admin = create(:user, :admin)
    expect(admin).to be_valid
  end

  it "should create user with default assessor role if no role is provided" do
    user = create(:user)
    expect(user.role == "assessor").to be_truthy
  end
end
