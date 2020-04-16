# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  it "should create user successfully" do
    assessor = create(:user, :assessor)
    expect(assessor).to be_valid
  end

  it "should create user with reviewer role" do
    reviewer = create(:user, :reviewer)
    expect(reviewer).to be_valid
  end

  it "should create user with admin role" do
    admin = create(:user, :admin)
    expect(admin).to be_valid
  end

  it "should save reviewer role correctly" do
    reviewer = create(:user, :reviewer)
    expect(reviewer.role).to eq "reviewer"
  end

  it "should save admin role correctly" do
    admin = create(:user, :admin)
    expect(admin.role).to eq "admin"
  end

  it "should create user with default assessor role if no role is provided" do
    user = create(:user)
    expect(user.role).to eq "assessor"
  end

  it "should create user with default assessor role if no role is provided" do
    user = create(:user)
    expect(user.role == "assessor").to be_truthy
  end

  it "should not be created without a password" do
    user_without_password = build(:user, password: nil)
    expect(user_without_password).to_not be_valid
  end

  it "should not be created without an email" do
    email = build(:user, email: nil)
    expect(email).to_not be_valid
  end
end
