# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationMailer, type: :mailer do
  let(:local_authority) do
    create :local_authority,
           name: "Cookie authority",
           subdomain: "cookies",
           signatory_name: "Mr. Biscuit",
           signatory_job_title: "Lord of BiscuitTown",
           enquiries_paragraph: "reach us on postcode SW50",
           email_address: "biscuit@somuchbiscuit.com"
  end

  let!(:reviewer) { create :user, :reviewer, local_authority: local_authority }
  let!(:assessor) { create :user, :assessor, local_authority: local_authority }
  let!(:planning_application) { create(:planning_application, :determined, local_authority: local_authority, decision: "granted") }
  let(:host) { "default.example.com" }
  let!(:change_request) { create(:description_change_request, planning_application: planning_application, user: assessor) }

  let!(:document_with_tags) do
    create :document, :with_tags,
           planning_application: planning_application,
           numbers: "proposed_number_1, proposed_number_2",
           referenced_in_decision_notice: true
  end

  let!(:archived_document_with_tags) do
    create :document, :archived, :with_tags,
           planning_application: planning_application,
           numbers: "archived_number"
  end

  describe "#decision_notice_mail" do
    let(:mail) { described_class.decision_notice_mail(planning_application.reload, host) }

    it "renders the headers" do
      expect(mail.subject).to eq("Certificate of Lawfulness: granted")
      expect(mail.to).to eq([planning_application.applicant_email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include("Your Certificate of lawful development (proposed) has been granted.")
      expect(mail.body.encoded).to include(decision_notice_api_v1_planning_application_path(planning_application, format: "pdf"))
    end

    context "for a rejected application" do
      let(:planning_application) do
        create :planning_application, :determined, decision: "refused",
                                                   public_comment: "not valid"
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
    let(:validation_mail) { described_class.validation_notice_mail(planning_application, host) }

    ENV["APPLICANTS_APP_HOST"] = "example.com"

    it "renders the headers" do
      expect(validation_mail.subject).to eq("Your planning application has been validated")
      expect(validation_mail.to).to eq([planning_application.applicant_email])
    end

    it "renders the body" do
      expect(validation_mail.body.encoded).to match("started from #{planning_application.documents_validated_at.strftime('%e %B %Y')}")
      expect(validation_mail.body.encoded).to match("issue a decision by #{planning_application.target_date.strftime('%e %B %Y')}")
      expect(validation_mail.body.encoded).to match("issue a decision by #{planning_application.target_date.strftime('%e %B %Y')}")
      expect(validation_mail.body.encoded).to match("Site Address: #{planning_application.full_address}")
      expect(validation_mail.body.encoded).to match("planning reference number #{planning_application.reference}")
      expect(validation_mail.body.encoded).to match("Proposal: #{planning_application.description}")
    end
  end

  describe "#change_request_mail" do
    let(:change_request_mail) { described_class.change_request_mail(planning_application.reload, change_request) }

    ENV["APPLICANTS_APP_HOST"] = "localhost"

    it "renders the headers" do
      expect(change_request_mail.subject).to eq("Your planning application at: #{planning_application.full_address}")
      expect(change_request_mail.to).to eq([planning_application.applicant_email])
    end

    it "renders the body" do
      expect(change_request_mail.body.encoded).to include("Application received: #{planning_application.created_at.strftime('%e %B %Y')}")
      expect(change_request_mail.body.encoded).to include(change_request.user.name)
      expect(change_request_mail.body.encoded).to include(change_request.response_due.strftime("%e %B %Y"))
      expect(change_request_mail.body.encoded).to include(planning_application.change_access_id)
      expect(change_request_mail.body.encoded).to include("http://cookies.localhost/change_requests?planning_application_id=#{planning_application.id}&change_access_id=#{planning_application.change_access_id}")
      expect(change_request_mail.body.encoded).to include("Mr. Biscuit")
      expect(change_request_mail.body.encoded).to include("Cookie authority")
      expect(change_request_mail.body.encoded).to include("Lord of BiscuitTown")
    end
  end
end
