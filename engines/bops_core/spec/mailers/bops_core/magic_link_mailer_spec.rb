# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe BopsCore::MagicLinkMailer, type: :mailer do
  describe "magic_link_mail" do
    let(:consultation) { create(:consultation) }
    let(:consultee) { create(:consultee, consultation:, email_address: "consultee@example.com", name: "Bops Consultee") }
    let(:planning_application) { consultation.planning_application }
    let(:mail) { described_class.magic_link_mail(resource: consultee, planning_application:, email: consultee.email_address, subject: "Your magic link") }

    before do
      allow(consultee).to receive(:sgid).and_return("123456789")
    end

    it "renders the subject" do
      expect(mail.subject).to eq("Your magic link")
    end

    it "sends to the correct email address" do
      expect(mail.to).to eq([consultee.email_address])
    end

    it "assigns the correct magic link URL" do
      expect(mail.body.encoded).to include("http://buckinghamshire.bops.services/consultees/planning_applications/#{planning_application.reference}?sgid=123456789")
    end

    it "includes the planning application reference in the email body" do
      expect(mail.body.encoded).to include("This is your magic link to view BOPS application: #{planning_application.reference_in_full}")
    end
  end
end
