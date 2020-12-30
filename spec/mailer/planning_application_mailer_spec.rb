# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationMailer, type: :mailer do
  describe "#decision_notice_mail" do
    let(:local_authority) {
      create :local_authority,
      name: "Cookie authority",
      signatory_name: "Mr. Biscuit",
      signatory_job_title: "Lord of BiscuitTown",
      enquiries_paragraph: "reach us on postcode SW50",
      email_address: "biscuit@somuchbiscuit.com"
      }

    let!(:reviewer) { create :user, :reviewer, local_authority: local_authority }
    let!(:planning_application) { create(:planning_application, :determined, local_authority: local_authority) }
    let!(:decision) { create(:decision, :granted, user: reviewer, planning_application: planning_application) }

    let!(:document_with_proposed_tags) do
      create :document, :proposed_tags,
             planning_application: planning_application,
             numbers: "proposed_number_1, proposed_number_2"
    end

    let!(:archived_document_with_proposed_tags) do
      create :document, :archived, :proposed_tags,
             planning_application: planning_application,
             numbers: "archived_number"
    end

    let!(:document_with_existing_tags) do
      create :document, :existing_tags,
             planning_application: planning_application,
             numbers: "existing_number"
    end

    let(:mail) { PlanningApplicationMailer.decision_notice_mail(planning_application.reload) }

    it "renders the headers" do
      expect(mail.subject).to eq("Certificate of Lawfulness: granted")
      expect(mail.to).to eq([decision.planning_application.applicant_email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Certificate of lawfulness of proposed use or development: granted.")
      expect(mail.body.encoded).to match("Applicant: #{planning_application.applicant_first_name} #{planning_application.applicant_last_name}")
      expect(mail.body.encoded).to match("Date of Issue of this decision: #{planning_application.determined_at.strftime("%e %B %Y")}")
      expect(mail.body.encoded).to match("Application received: #{planning_application.created_at.strftime("%e %B %Y")}")
      expect(mail.body.encoded).to match("Address: #{planning_application.site.full_address}")
      expect(mail.body.encoded).to match("Application number: #{planning_application.reference}")
      expect(mail.body.encoded).to match("Local authority: #{planning_application.local_authority.name}")
    end

    it "renders numbers for active documents with proposed tags" do
      expect(mail.body.encoded).to match("proposed_number_1")
      expect(mail.body.encoded).to match("proposed_number_2")
    end

    it "renders the name of the correct local authority signatory" do
      expect(mail.body.encoded).to match("Cookie authority")
      expect(mail.body.encoded).to match("Mr. Biscuit")
      expect(mail.body.encoded).to match("Lord of BiscuitTown")
      expect(mail.body.encoded).to match("reach us on postcode SW50")
      expect(mail.body.encoded).to match("biscuit@somuchbiscuit.com")
    end

    it "does not render numbers for archived documents with proposed tags" do
      expect(mail.body.encoded).not_to match("archived_number")
    end

    it "does not render numbers for active documents that have only existing tags" do
      expect(mail.body.encoded).not_to match("existing_number")
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
