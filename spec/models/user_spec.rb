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

  describe "#create" do
    let(:user) { build(:user) }

    before do
      allow(described_class)
        .to receive(:generate_otp_secret)
        .and_return("7YK63IMOL76DMZRGU3KN2CLS")
    end

    it "sets otp_required_for_login to true" do
      expect { user.save }
        .to change(user, :otp_required_for_login)
        .from(nil)
        .to(true)
    end

    it "sets otp_secret" do
      expect { user.save }
        .to change(user, :otp_secret)
        .from(nil)
        .to("7YK63IMOL76DMZRGU3KN2CLS")
    end

    context "when mobile_number is blank" do
      let(:user) { build(:user, mobile_number: nil) }

      it "fails" do
        expect { user.save }
          .to change { user.errors[:mobile_number] }
          .from([])
          .to ["can't be blank"]
      end
    end
  end

  describe "#mobile_number" do
    context "when one time password required for log in" do
      let(:user) do
        build(:user, otp_required_for_login: true, mobile_number: nil)
      end

      it "is required" do
        expect { user.valid? }
          .to change { user.errors[:mobile_number] }
          .from([])
          .to ["can't be blank"]
      end
    end

    # for convenience some preview users don't require 2FA
    context "when one time password not required for log in" do
      let(:user) do
        create(:user).tap do |u|
          u.update!(otp_required_for_login: false, mobile_number: nil)
        end
      end

      it "is not required" do
        expect(user.valid?).to eq(true)
      end
    end

    context "when it contains non digits" do
      let(:user) { build(:user, mobile_number: "not a number") }

      it "is invalid" do
        expect { user.valid? }
          .to change { user.errors[:mobile_number] }
          .to ["is invalid"]
      end
    end

    context "when it contains only digits" do
      let(:user) { build(:user, mobile_number: "01234123123") }

      it "is valid" do
        expect(user.valid?).to eq(true)
      end
    end
  end
end
