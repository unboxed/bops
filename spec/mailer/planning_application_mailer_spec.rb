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
  let!(:planning_application) { create(:planning_application, :determined, agent_email: "cookie_crackers@example.com", applicant_email: "cookie_crumbs@example.com", local_authority: local_authority, decision: "granted") }
  let(:host) { "default.example.com" }
  let!(:validation_request) { create(:description_change_validation_request, planning_application: planning_application, user: assessor) }

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
    end

    it "emails the applicant when only the applicant is present" do
      planning_application.update!(agent_email: "")
      mail = described_class.decision_notice_mail(planning_application.reload, host)

      expect(mail.to).to eq([planning_application.applicant_email])
    end

    it "emails both applicant and agent when both are present" do
      expect(mail.subject).to eq("Certificate of Lawfulness: granted")
      expect(mail.to).to eq([planning_application.agent_email])
      expect(mail.bcc).to eq([planning_application.applicant_email])
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

  describe "#invalidation_notice_mail" do
    let!(:planning_application) { create(:planning_application, :invalidated, local_authority: local_authority) }

    let!(:validation_request) { create(:description_change_validation_request, planning_application: planning_application, user: assessor) }

    let(:invalidation_mail) { described_class.invalidation_notice_mail(planning_application, host) }

    ENV["APPLICANTS_APP_HOST"] = "example.com"

    it "renders the headers" do
      expect(invalidation_mail.subject).to eq("Your planning application is invalid")
      expect(invalidation_mail.to).to eq([planning_application.agent_email])
      expect(invalidation_mail.bcc).to eq([planning_application.applicant_email])
    end

    it "renders the body" do
      expect(invalidation_mail.body.encoded).to include("http://cookies.example.com/validation_requests?planning_application_id=#{planning_application.id}&change_access_id=#{planning_application.change_access_id}")
      expect(invalidation_mail.body.encoded).to include("Site Address: #{planning_application.full_address}")
      expect(invalidation_mail.body.encoded).to include("Reference No.: #{planning_application.reference}")
      expect(invalidation_mail.body.encoded).to include("Proposal: #{planning_application.description}")
    end
  end

  describe "#validation_notice_mail" do
    let(:validation_mail) { described_class.validation_notice_mail(planning_application, host) }

    ENV["APPLICANTS_APP_HOST"] = "example.com"

    it "renders the headers" do
      expect(validation_mail.subject).to eq("Your planning application has been validated")
      if planning_application.agent_email.present?
        expect(validation_mail.to).to eq([planning_application.agent_email])
      else
        expect(validation_mail.to).to eq([planning_application.applicant_email])
      end
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

  describe "#validation_request_mail" do
    let(:validation_request_mail) { described_class.validation_request_mail(planning_application.reload, validation_request) }

    ENV["APPLICANTS_APP_HOST"] = "localhost"

    it "renders the headers" do
      expect(validation_request_mail.subject).to eq("Your planning application at: #{planning_application.full_address}")
      if planning_application.agent_email.present?
        expect(validation_request_mail.to).to eq([planning_application.agent_email])
      else
        expect(validation_request_mail.to).to eq([planning_application.applicant_email])
      end
    end

    it "renders the body" do
      expect(validation_request_mail.body.encoded).to include("Application received: #{planning_application.created_at.strftime('%e %B %Y')}")
      expect(validation_request_mail.body.encoded).to include(validation_request.user.name)
      expect(validation_request_mail.body.encoded).to include(validation_request.response_due.strftime("%e %B %Y"))
      expect(validation_request_mail.body.encoded).to include(planning_application.change_access_id)
      expect(validation_request_mail.body.encoded).to include("http://cookies.example.com/validation_requests?planning_application_id=#{planning_application.id}&change_access_id=#{planning_application.change_access_id}")
      expect(validation_request_mail.body.encoded).to include("Mr. Biscuit")
      expect(validation_request_mail.body.encoded).to include("Cookie authority")
      expect(validation_request_mail.body.encoded).to include("Lord of BiscuitTown")
    end
  end

  describe "#receipt_notice_mail" do
    let(:receipt_mail) { described_class.receipt_notice_mail(planning_application, host) }

    ENV["APPLICANTS_APP_HOST"] = "example.com"

    it "renders the headers" do
      expect(receipt_mail.subject).to eq("We have received your application")
      expect(receipt_mail.to).to eq([planning_application.agent_email])
      expect(receipt_mail.bcc).to eq([planning_application.applicant_email])
    end

    it "renders the body" do
      expect(receipt_mail.body.encoded).to match("If by #{planning_application.target_date.strftime('%e %B %Y')}:")
      expect(receipt_mail.body.encoded).to match("Date received: #{planning_application.created_at.strftime('%e %B %Y - %H:%M:%S')}")
      expect(receipt_mail.body.encoded).to match("Site address: #{planning_application.full_address}")
      expect(receipt_mail.body.encoded).to match("Reference: #{planning_application.reference}")
      expect(receipt_mail.body.encoded).to match("Description: #{planning_application.description}")
    end
  end
end
