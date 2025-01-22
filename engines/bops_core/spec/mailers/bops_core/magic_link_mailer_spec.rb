# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe BopsCore::MagicLinkMailer, type: :mailer do
  describe "magic_link_mail" do
    let(:consultation) { create(:consultation) }
    let(:consultee) { create(:consultee, consultation:, email_address: "consultee@example.com", name: "Bops Consultee") }
    let(:planning_application) { consultation.planning_application }
    let(:mail) { described_class.magic_link_mail(resource: consultee, planning_application:, subdomain: "southwark", subject: "Your magic link") }

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
      expect(mail.body.encoded).to include("http://southwark.bops.services/consultees/planning_applications/25-00100-LDCE?sgid=123456789")
    end

    it "includes the planning application reference in the email body" do
      expect(mail.body.encoded).to include("View BOPS application: #{planning_application.reference_in_full}")
    end

    it "includes the link expiration information" do
      expect(mail.body.encoded).to include("This link will expire in 48 hours.")
    end
  end
end
