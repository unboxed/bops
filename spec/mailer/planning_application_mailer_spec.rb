# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationMailer, type: :mailer do
  let(:local_authority) do
    create :local_authority,
           name: "Cookie authority",
           signatory_name: "Mr. Biscuit",
           signatory_job_title: "Lord of BiscuitTown",
           enquiries_paragraph: "reach us on postcode SW50",
           email_address: "biscuit@somuchbiscuit.com"
  end

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

  describe "#decision_notice_mail" do
    let(:mail) { described_class.decision_notice_mail(planning_application.reload) }

    it "renders the headers" do
      expect(mail.subject).to eq("Certificate of Lawfulness: granted")
      expect(mail.to).to eq([decision.planning_application.applicant_email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include("Your Certificate of lawful development (proposed) has been granted.")
      expect(mail.body.encoded).to include(decision_notice_api_v1_planning_application_path(planning_application, format: "pdf"))
    end

    context "for a rejected application" do
      before do
        decision.refused!
      end

      it "includes the status in the subject" do
        expect(mail.subject).to eq("Certificate of Lawfulness: refused")
      end

      it "includes the status in the body" do
        expect(mail.body.encoded).to include("Your Certificate of lawful development (proposed) has been refused.")
        expect(mail.body.encoded).to include(decision_notice_api_v1_planning_application_path(planning_application, format: "pdf"))
      end
    end
  end

  describe "#validation_notice_mail" do
    let(:validation_mail) { described_class.validation_notice_mail(planning_application.reload) }

    it "renders the headers" do
      expect(validation_mail.subject).to eq("Your planning application has been validated")
      expect(validation_mail.to).to eq([planning_application.applicant_email])
    end

    it "renders the body" do
      expect(validation_mail.body.encoded).to match("started from #{planning_application.documents_validated_at.strftime('%e %B %Y')}")
      expect(validation_mail.body.encoded).to match("issue a decision by #{planning_application.target_date.strftime('%e %B %Y')}")
      expect(validation_mail.body.encoded).to match("issue a decision by #{planning_application.target_date.strftime('%e %B %Y')}")
      expect(validation_mail.body.encoded).to match("Site Address: #{planning_application.site.full_address}")
      expect(validation_mail.body.encoded).to match("planning reference number #{planning_application.reference}")
      expect(validation_mail.body.encoded).to match("Proposal: #{planning_application.description}")
    end
  end
end
