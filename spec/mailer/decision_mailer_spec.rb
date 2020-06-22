# frozen_string_literal: true

require "rails_helper"

RSpec.describe DecisionMailer, type: :mailer do
  describe "#decision_notice_mail" do
    let(:reviewer) { create :user, :reviewer }
    let(:planning_application) { create(:planning_application) }
    let(:decision) { create(:decision, :granted, user: reviewer, planning_application: planning_application) }

    let(:mail) { DecisionMailer.decision_notice_mail(decision) }

    it "renders the headers" do
      expect(mail.subject).to eq("Certificate of Lawfulness: #{decision.status}")
      expect(mail.to).to eq([decision.planning_application.applicant.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Certificate of lawfulness of proposed use or development: #{decision.status}.")
      expect(mail.body.encoded).to match("Applicant: #{planning_application.applicant.full_name}")
      expect(mail.body.encoded).to match("Date of Issue of this decision: #{decision.determined_at.strftime("%d/%m/%Y")}")
      expect(mail.body.encoded).to match("Application received: #{planning_application.created_at.strftime("%d/%m/%Y")}")
      expect(mail.body.encoded).to match("Address: #{planning_application.site.full_address}")
      expect(mail.body.encoded).to match("Application number: #{planning_application.reference}")
    end
  end
end
