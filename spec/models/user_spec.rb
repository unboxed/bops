# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
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
        expect(user.otp_required_for_login).to be(true)
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

  describe "#mobile_number" do
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
        expect(user.valid?).to be(true)
      end
    end
  end

  describe "#send_otp_by_sms?" do
    context "when otp_delivery_method is sms" do
      let(:user) { build(:user, otp_delivery_method: :sms) }

      it "returns true" do
        expect(user.send_otp_by_sms?).to be(true)
      end
    end

    context "when otp_delivery_method is email" do
      let(:user) { build(:user, otp_delivery_method: :email) }

      it "returns false" do
        expect(user.send_otp_by_sms?).to be(false)
      end
    end
  end

  describe "#send_otp" do
    let(:session_mobile_number) { "07717123123" }

    context "when otp_delivery_method is email" do
      let(:user) do
        create(:user, otp_delivery_method: :email, email: "jane@example.com")
      end

      let(:email) { ActionMailer::Base.deliveries.last }

      before { user.send_otp(session_mobile_number) }

      it "sends email to correct address" do
        expect(email.to).to contain_exactly("jane@example.com")
      end

      it "sends correct otp" do
        expect(email.body.encoded).to include(user.current_otp)
      end
    end

    context "when otp_delivery_method is sms" do
      let(:user) do
        create(:user, otp_delivery_method: :sms, mobile_number: "07717456456")
      end

      let(:expected_args) do
        {
          template_id: "701e32b3-2c8c-4c16-9a1b-c883ef6aedee",
          phone_number: "07717456456",
          personalisation: {
            otp: user.current_otp
          }
        }
      end

      it "sends sms with correct information to user mobile number" do
        expect_any_instance_of(Notifications::Client)
          .to receive(:send_sms)
          .with(expected_args)

        user.send_otp(session_mobile_number)
      end

      context "when mobile number is blank" do
        let(:user) do
          create(:user, otp_delivery_method: :sms, mobile_number: nil)
        end

        let(:expected_args) do
          {
            template_id: "701e32b3-2c8c-4c16-9a1b-c883ef6aedee",
            phone_number: "07717123123",
            personalisation: {
              otp: user.current_otp
            }
          }
        end

        it "returns sms with otp to session mobile number" do
          expect_any_instance_of(Notifications::Client)
            .to receive(:send_sms)
            .with(expected_args)

          user.send_otp(session_mobile_number)
        end
      end
    end
  end
end
