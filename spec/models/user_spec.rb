# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  it "creates user successfully" do
    assessor = create(:user, :assessor)
    expect(assessor).to be_valid
  end

  it "creates user with reviewer role" do
    reviewer = create(:user, :reviewer)
    expect(reviewer).to be_valid
  end

  it "saves reviewer role correctly" do
    reviewer = create(:user, :reviewer)
    expect(reviewer.role).to eq "reviewer"
  end

  it "creates user with default assessor role if no role is provided" do
    user = create(:user)
    expect(user.role).to eq "assessor"
  end

  it "creates user with default assessor role if no role is provided" do
    user = create(:user)
    expect(user.role == "assessor").to be_truthy
  end

  it "is not created without a password" do
    user_without_password = build(:user, password: nil)
    expect(user_without_password).not_to be_valid
  end

  it "is not created without an email" do
    email = build(:user, email: nil)
    expect(email).not_to be_valid
  end

  it "is not created without a local authority" do
    user_without_local_authority = build(:user, local_authority: nil)
    expect(user_without_local_authority).not_to be_valid
  end

  it "does not allow for duplicate users within the same domain" do
    domain = create(:local_authority)
    user_one = create(:user, email: "pompom@pom.com", local_authority: domain)
    user_two = build(:user, email: "pompom@pom.com", local_authority: domain)

    expect(user_two.save).to be false
    expect(user_two.errors.messages[:email]).to include("has already been taken")
  end

  it "does not allow for duplicate users in separate domains" do
    domain_one = create(:local_authority)
    domain_two = create(:local_authority)

    user_one = create(:user, email: "gali@galileo.com", local_authority: domain_one)
    user_two = build(:user, email: "gali@galileo.com", local_authority: domain_two)

    expect(user_two.save).to be false
    expect(user_two.errors.messages[:email]).to include("has already been taken")
  end
end
