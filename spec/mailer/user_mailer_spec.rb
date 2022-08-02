# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "#update_notification_mail" do
    let(:planning_application) { create(:planning_application) }

    let(:mail) do
      described_class.update_notification_mail(
        planning_application,
        "assessor@example.com"
      )
    end

    let(:mail_body) { mail.body.encoded }

    it "sets subject" do
      travel_to(Date.new(2022)) do
        expect(mail.subject).to eq(
          "BoPS case BUC-22-00100-LDCP has a new update"
        )
      end
    end

    it "sets recipient" do
      expect(mail.to).to contain_exactly("assessor@example.com")
    end

    it "includes planning application reference" do
      travel_to(Date.new(2022)) do
        expect(mail_body).to include(
          "BoPS case BUC-22-00100-LDCP has a new update."
        )
      end
    end

    it "includes plannng application url" do
      expect(mail_body).to include(
        "http://buckinghamshire.bops.services/planning_applications/#{planning_application.id}"
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
  end
end
