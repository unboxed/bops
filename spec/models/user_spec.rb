# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    subject(:user) { described_class.new }

    describe "#local_authority" do
      it "validates presence" do
        expect { user.valid? }.to change { user.errors[:local_authority] }.to ["must exist"]
      end
    end
  end

  describe "instance methods" do
    let(:user) { create(:user) }

    describe "#assign_mobile_number!" do
      it "updates a user's mobile number" do
        expect do
          user.assign_mobile_number!("07766759254")
        end.to change(user, :mobile_number).to("07766759254")
      end
    end

    describe "#valid_otp_attempt?" do
      it "returns true when a valid otp attempt has been made" do
        expect(user.valid_otp_attempt?(user.current_otp)).to be(true)
      end

      it "returns false when an invalid otp attempt has been made" do
        expect(user.valid_otp_attempt?("123456")).to be(false)
      end
    end
  end

  describe "callbacks" do
    describe "::before_create #generate_otp_secret" do
      before do
        allow(described_class).to receive(:generate_otp_secret).and_return("7YK63IMOL76DMZRGU3KN2CLS")
      end

      let(:user) { create(:user) }

      it "sets relevant otp fields on the user record" do
        expect(user.otp_required_for_login).to eq(true)
        expect(user.otp_secret).to eq("7YK63IMOL76DMZRGU3KN2CLS")
      end
    end
  end

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
    create(:user, email: "pompom@pom.com", local_authority: domain)
    user_two = build(:user, email: "pompom@pom.com", local_authority: domain)

    expect(user_two.save).to be false
    expect(user_two.errors.messages[:email]).to include("has already been taken")
  end

  it "does not allow for duplicate users in separate domains" do
    domain_one = create(:local_authority, :southwark)
    domain_two = create(:local_authority, :lambeth)

    create(:user, email: "gali@galileo.com", local_authority: domain_one)
    user_two = build(:user, email: "gali@galileo.com", local_authority: domain_two)

    expect(user_two.save).to be false
    expect(user_two.errors.messages[:email]).to include("has already been taken")
  end
end
