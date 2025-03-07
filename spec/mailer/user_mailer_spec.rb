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
