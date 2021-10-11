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
  let!(:planning_application) do
    create(:planning_application, :determined, agent_email: "cookie_crackers@example.com",
                                               applicant_email: "cookie_crumbs@example.com", local_authority: local_authority, decision: "granted")
  end
  let(:host) { "default.example.com" }
  let!(:validation_request) do
    create(:description_change_validation_request, planning_application: planning_application, user: assessor)
  end

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
    let(:mail) do
      described_class.decision_notice_mail(planning_application.reload, host, planning_application.applicant_email)
    end

    it "renders the headers" do
      expect(mail.subject).to eq("Certificate of Lawfulness: granted")
    end

    it "emails the applicant when only the applicant is present" do
      planning_application.update!(agent_email: "")
      mail = described_class.decision_notice_mail(planning_application.reload, host,
                                                  [planning_application.agent_email, planning_application.applicant_email])

      expect(mail.to).to eq([planning_application.applicant_email])
    end

    it "emails both applicant and agent when both are present" do
      expect(mail.subject).to eq("Certificate of Lawfulness: granted")
      expect(mail.to).to eq([planning_application.applicant_email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include("Your Certificate of lawful development (proposed) has been granted.")
      expect(mail.body.encoded).to include(decision_notice_api_v1_planning_application_path(planning_application,
                                                                                            format: "pdf"))
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
        expect(mail.body.encoded).to include(decision_notice_api_v1_planning_application_path(planning_application,
                                                                                              format: "pdf"))
      end

      it "includes the name of the agent in the body if agent is present" do
        expect(mail.body.encoded).to include(planning_application.agent_first_name)
        expect(mail.body.encoded).to include(planning_application.agent_last_name)
      end

      it "includes the name of the applicant in the body if no agent is present" do
        planning_application.update!(agent_first_name: "")
        mail = described_class.decision_notice_mail(planning_application.reload, host,
                                                    [planning_application.agent_email, planning_application.applicant_email])

        expect(mail.body.encoded).to include(planning_application.applicant_first_name)
        expect(mail.body.encoded).to include(planning_application.applicant_last_name)
      end
    end
  end

  describe "#invalidation_notice_mail" do
    let!(:planning_application) { create(:planning_application, :invalidated, local_authority: local_authority) }

    let!(:validation_request) do
      create(:description_change_validation_request, planning_application: planning_application, user: assessor)
    end

    let(:invalidation_mail) { described_class.invalidation_notice_mail(planning_application, host) }

    ENV["APPLICANTS_APP_HOST"] = "example.com"

    it "emails only the agent when the agent is present" do
      expect(invalidation_mail.to).to eq([planning_application.agent_email])
    end

    it "emails only the applicant when the agent is missing" do
      planning_application.update!(agent_email: "")
      mail = described_class.invalidation_notice_mail(planning_application.reload, host)

      expect(mail.to).to eq([planning_application.applicant_email])
    end

    it "renders the headers" do
      expect(invalidation_mail.subject).to eq("Your planning application is invalid")
    end

    it "renders the body" do
      expect(invalidation_mail.body.encoded).to include("http://cookies.example.com/validation_requests?planning_application_id=#{planning_application.id}&change_access_id=#{planning_application.change_access_id}")
      expect(invalidation_mail.body.encoded).to include("Site Address: #{planning_application.full_address}")
      expect(invalidation_mail.body.encoded).to include("Reference No.: #{planning_application.reference}")
      expect(invalidation_mail.body.encoded).to include("Proposal: #{planning_application.description}")
    end
  end

  describe "#validation_notice_mail" do
    let(:validation_mail) do
      described_class.validation_notice_mail(planning_application, host,
                                             [planning_application.agent_email, planning_application.applicant_email])
    end

    ENV["APPLICANTS_APP_HOST"] = "example.com"

    it "renders the headers" do
      expect(validation_mail.subject).to eq("Your planning application has been validated")
      expect(validation_mail.to).to eq([planning_application.agent_email, planning_application.applicant_email])
    end

    it "emails only the applicant when the agent is missing" do
      planning_application.update!(agent_email: "")
      mail = described_class.validation_notice_mail(planning_application.reload, host,
                                                    [planning_application.agent_email, planning_application.applicant_email])

      expect(mail.to).to eq([planning_application.applicant_email])
    end

    it "renders the body" do
      expect(validation_mail.body.encoded).to match("started from #{planning_application.documents_validated_at.to_formatted_s(:day_month_year)}")
      expect(validation_mail.body.encoded).to match("issue a decision by #{planning_application.target_date.to_formatted_s(:day_month_year)}")
      expect(validation_mail.body.encoded).to match("issue a decision by #{planning_application.target_date.to_formatted_s(:day_month_year)}")
      expect(validation_mail.body.encoded).to match("Site Address: #{planning_application.full_address}")
      expect(validation_mail.body.encoded).to match("planning reference number #{planning_application.reference}")
      expect(validation_mail.body.encoded).to match("Proposal: #{planning_application.description}")
    end
  end

  describe "#validation_request_mail" do
    let(:validation_request_mail) do
      described_class.validation_request_mail(planning_application.reload, validation_request)
    end

    ENV["APPLICANTS_APP_HOST"] = "localhost"

    it "emails only the agent when the agent is present" do
      expect(validation_request_mail.to).to eq([planning_application.agent_email])
    end

    it "emails only the applicant when the agent is missing" do
      planning_application.update!(agent_email: "")
      mail = described_class.validation_request_mail(planning_application.reload, validation_request)

      expect(mail.to).to eq([planning_application.applicant_email])
    end

    it "renders the headers" do
      expect(validation_request_mail.subject).to eq("Your planning application at: #{planning_application.full_address}")
      expect(validation_request_mail.to).to eq([planning_application.agent_email])
    end

    it "renders the body" do
      expect(validation_request_mail.body.encoded).to include("Application received: #{planning_application.created_at.to_formatted_s(:day_month_year)}")
      expect(validation_request_mail.body.encoded).to include(validation_request.user.name)
      expect(validation_request_mail.body.encoded).to include(validation_request.response_due.to_formatted_s(:day_month_year))
      expect(validation_request_mail.body.encoded).to include(planning_application.change_access_id)
      expect(validation_request_mail.body.encoded).to include("http://cookies.example.com/validation_requests?planning_application_id=#{planning_application.id}&change_access_id=#{planning_application.change_access_id}")
      expect(validation_request_mail.body.encoded).to include("Mr. Biscuit")
      expect(validation_request_mail.body.encoded).to include("Cookie authority")
      expect(validation_request_mail.body.encoded).to include("Lord of BiscuitTown")
    end

    it "includes the name of the agent in the body if agent is present" do
      expect(validation_request_mail.body.encoded).to include(planning_application.agent_first_name)
      expect(validation_request_mail.body.encoded).to include(planning_application.agent_last_name)
    end

    it "includes the name of the applicant in the body if no agent is present" do
      planning_application.update!(agent_first_name: "")
      mail = described_class.validation_request_mail(planning_application.reload, validation_request)

      expect(mail.body.encoded).to include(planning_application.applicant_first_name)
      expect(mail.body.encoded).to include(planning_application.applicant_last_name)
    end
  end

  describe "#receipt_notice_mail" do
    let(:receipt_mail) do
      described_class.receipt_notice_mail(planning_application, host,
                                          [planning_application.agent_email, planning_application.applicant_email])
    end

    ENV["APPLICANTS_APP_HOST"] = "example.com"

    it "renders the headers" do
      expect(receipt_mail.subject).to eq("We have received your application")
      expect(receipt_mail.to).to eq([planning_application.agent_email, planning_application.applicant_email])
    end

    it "renders the body" do
      expect(receipt_mail.body.encoded).to match("If by #{planning_application.target_date.to_formatted_s(:day_month_year)}:")
      expect(receipt_mail.body.encoded).to match("Date received: #{Time.first_business_day(planning_application.created_at).to_formatted_s(:day_month_year)}")
      expect(receipt_mail.body.encoded).to match("Site address: #{planning_application.full_address}")
      expect(receipt_mail.body.encoded).to match("Reference: #{planning_application.reference}")
      expect(receipt_mail.body.encoded).to match("Description: #{planning_application.description}")
    end
  end
end
