# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationMailer, type: :mailer do
  describe "#decision_notice_mail" do
    let!(:reviewer) { create :user, :reviewer }
    let!(:planning_application) { create(:planning_application, :determined) }
    let!(:decision) { create(:decision, :granted, user: reviewer, planning_application: planning_application) }

    let(:mail) { PlanningApplicationMailer.decision_notice_mail(planning_application.reload) }

    it "renders the headers" do
      expect(mail.subject).to eq("Certificate of Lawfulness: granted")
      expect(mail.to).to eq([decision.planning_application.applicant.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Certificate of lawfulness of proposed use or development: granted.")
      expect(mail.body.encoded).to match("Applicant: #{planning_application.applicant.full_name}")
      expect(mail.body.encoded).to match("Date of Issue of this decision: #{planning_application.determined_at.strftime("%e %B %Y")}")
      expect(mail.body.encoded).to match("Application received: #{planning_application.created_at.strftime("%e %B %Y")}")
      expect(mail.body.encoded).to match("Address: #{planning_application.site.full_address}")
      expect(mail.body.encoded).to match("Application number: #{planning_application.reference}")
    end

    context "for a rejected application" do
      before do
        decision.refused!
      end

      it "includes the status in the subject" do
        expect(mail.subject).to eq("Certificate of Lawfulness: refused")
      end

      it "includes the status in the body" do
        expect(mail.body.encoded).to match("Certificate of lawfulness of proposed use or development: refused.")
      end
    end
  end
end
