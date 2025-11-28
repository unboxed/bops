# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "#update_notification_mail" do
    let(:planning_application) { create(:planning_application, :ldc_proposed) }

    let(:mail) do
      described_class.update_notification_mail(
        planning_application,
        "assessor@example.com"
      )
    end

    let(:mail_body) { mail.body.encoded }

    it "sets subject" do
      travel_to("2022-01-01 00:00:00 GMT") do
        expect(mail.subject).to eq(
          "BOPS case BUC-22-00100-LDCP has a new update"
        )
      end
    end

    it "sets recipient" do
      expect(mail.to).to contain_exactly("assessor@example.com")
    end

    it "includes planning application reference" do
      travel_to("2022-01-01 00:00:00 GMT") do
        expect(mail_body).to include(
          "BOPS case BUC-22-00100-LDCP has a new update."
        )
      end
    end

    it "includes plannng application url" do
      expect(mail_body).to include(
        "http://buckinghamshire.bops.services/planning_applications/#{planning_application.reference}"
      )
    end
  end

  describe "#otp_mail" do
    let(:user) { create(:user, email: "jane@example.com") }
    let(:mail) { described_class.otp_mail(user) }
    let(:local_authority) { user.local_authority }

    it "sets subject" do
      expect(mail.subject).to eq(
        "Back Office Planning System verification code"
      )
    end

    it "sets recipient" do
      expect(mail.to).to contain_exactly("jane@example.com")
    end

    it "includes user's current otp" do
      expect(mail.body.encoded).to include(
        "#{user.current_otp} is your Back Office Planning System verification code."
      )
    end

    it "includes the otp expiry" do
      expect(mail.body.encoded).to include(
        "It will expire in 5 minutes."
      )
    end

    matcher :have_notify_header do |name, expected|
      match do |mail|
        mail.header[name]&.unparsed_value == expected
      end

      match_when_negated do |name|
        mail.header[name].blank?
      end

      failure_message do |mail|
        "expected message to have notify header #{name.inspect} matching #{expected.inspect} but it was #{mail.header[name]&.unparsed_value.inspect}"
      end
    end

    context "when the GOV.UK Notify account is enabled" do
      before do
        allow(local_authority).to receive(:enable_notify).and_return(true)
      end

      it "has the correct configuration" do
        expect(mail).to have_notify_header("template-id", "c56d9346-02be-4812-af6b-e254269c98d7")
        expect(mail).to have_notify_header("reply-to-id", "4896bb50-4f4c-4b4d-ad67-2caddddde125")
        expect(mail).to have_notify_header("delivery-method-settings", {api_key: "fake-c2a32a67-f437-46cd-9364-483d2cc4c43f-523849d3-ca3b-4c12-b11a-09ed7d86de2e"})
      end
    end

    context "when the GOV.UK Notify account is not enabled" do
      before do
        allow(local_authority).to receive(:enable_notify).and_return(false)
      end

      it "has the correct configuration" do
        expect(mail).to have_notify_header("template-id", "f51c953c-d3e3-4126-86f3-0d8927023472")
        expect(mail).to have_notify_header("reply-to-id", "3d0d2d5d-9b30-454c-9391-096ed8fef1d6")
        expect(mail).to have_notify_header("delivery-method-settings", {api_key: "testtest-8e9d49e4-ddf0-4b68-946f-f6c9554478f4-0b1c96fc-e505-4b58-98b0-a9d03838c700"})
      end
    end
  end

  describe "#assigned_notification_mail" do
    let!(:prior_approval) { create(:application_type, :prior_approval) }
    let(:planning_application) { create(:planning_application, :prior_approval, application_type: prior_approval) }

    let(:mail) do
      described_class.assigned_notification_mail(
        planning_application,
        "assessor@example.com"
      )
    end

    let(:mail_body) { mail.body.encoded }

    it "sets subject" do
      travel_to("2022-01-01 00:00:00 GMT") do
        expect(mail.subject).to eq(
          "You have been assigned to a prior approval case BUC-22-00100-PA1A"
        )
      end
    end

    it "sets recipient" do
      expect(mail.to).to contain_exactly("assessor@example.com")
    end

    it "includes planning application reference" do
      travel_to("2022-01-01 00:00:00 GMT") do
        expect(mail_body).to include(
          "You have been assigned to a prior approval case BUC-22-00100-PA1A."
        )
      end
    end

    it "includes plannng application url" do
      expect(mail_body).to include(
        "http://buckinghamshire.bops.services/planning_applications/#{planning_application.reference}"
      )
    end
  end

  describe "#password reset mail" do
    let(:user) { create(:user, :unconfirmed, email: "heidi@example.com") }

    it "sets subject" do
      user.send_confirmation_instructions
      mail = Devise.mailer.deliveries.last

      expect(mail.subject).to eq(
        "Set password instructions"
      )
      expect(mail.to).to contain_exactly("heidi@example.com")
      expect(mail.body.encoded).to include(
        "Welcome to the Back-office Planning System"
      )
    end
  end
end
