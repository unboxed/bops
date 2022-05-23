# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationMailer, type: :mailer do
  let(:local_authority) do
    create(
      :local_authority,
      name: "Cookie authority",
      subdomain: "cookies",
      signatory_name: "Mr. Biscuit",
      signatory_job_title: "Lord of BiscuitTown",
      enquiries_paragraph: "reach us on postcode SW50",
      email_address: "biscuit@somuchbiscuit.com",
      council_code: "ABC"
    )
  end

  let!(:reviewer) { create :user, :reviewer, local_authority: local_authority }
  let!(:assessor) { create :user, :assessor, local_authority: local_authority }

  let!(:planning_application) do
    create(
      :planning_application,
      :determined,
      agent_email: "cookie_crackers@example.com",
      applicant_email: "cookie_crumbs@example.com",
      local_authority: local_authority,
      decision: "granted",
      address_1: "123 High Street", # rubocop:disable Naming/VariableNumber
      town: "Big City",
      postcode: "AB3 4EF",
      description: "Add a chimney stack",
      created_at: DateTime.new(2022, 5, 1),
      application_type: "lawfulness_certificate",
      documents_validated_at: DateTime.new(2022, 10, 1)
    )
  end

  let!(:invalid_planning_application) { create(:planning_application, :invalidated) }

  let(:host) { "default.example.com" }
  let!(:validation_request) do
    create(:other_change_validation_request, planning_application: invalid_planning_application, user: assessor)
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

  before do
    ENV["APPLICANTS_APP_HOST"] = "example.com"
  end

  describe "#decision_notice_mail" do
    let(:mail) do
      described_class.decision_notice_mail(planning_application.reload, host, planning_application.applicant_email)
    end

    it "renders the headers" do
      expect(mail.subject).to eq("Lawful Development Certificate: granted")
    end

    it "emails the applicant when only the applicant is present" do
      planning_application.update!(agent_email: "")
      mail = described_class.decision_notice_mail(planning_application.reload, host,
                                                  [planning_application.agent_email, planning_application.applicant_email])

      expect(mail.to).to eq([planning_application.applicant_email])
    end

    it "emails both applicant and agent when both are present" do
      expect(mail.subject).to eq("Lawful Development Certificate: granted")
      expect(mail.to).to eq([planning_application.applicant_email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include("Your Lawful Development Certificate (proposed) has been granted.")
      expect(mail.body.encoded).to include(decision_notice_api_v1_planning_application_path(planning_application,
                                                                                            format: "pdf"))
    end

    context "for a rejected application" do
      let(:planning_application) do
        create :planning_application, :determined, decision: "refused",
                                                   public_comment: "not valid"
      end

      it "includes the status in the subject" do
        expect(mail.subject).to eq("Lawful Development Certificate: refused")
      end

      it "includes the status in the body" do
        expect(mail.body.encoded).to include("Your Lawful Development Certificate (proposed) has been refused.")
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
      create(:other_change_validation_request, planning_application: planning_application, user: assessor)
    end

    let(:invalidation_mail) { described_class.invalidation_notice_mail(planning_application, host) }

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
      expect(invalidation_mail.body.encoded).to include("Reference No.: #{planning_application.reference_in_full}")
      expect(invalidation_mail.body.encoded).to include("Proposal: #{planning_application.description}")
    end
  end

  describe "#validation_notice_mail" do
    let(:validation_mail) do
      described_class.validation_notice_mail(
        planning_application,
        planning_application.agent_email
      )
    end

    let(:mail_body) { validation_mail.body.encoded }

    it "sets the subject" do
      expect(validation_mail.subject).to eq(
        "Your application for a Lawful Development Certificate"
      )
    end

    it "sets the recipient" do
      expect(validation_mail.to).to contain_exactly(
        "cookie_crackers@example.com"
      )
    end

    it "includes the reference" do
      expect(mail_body).to include(
        "Application reference number: ABC-22-00100-LDCP"
      )
    end

    it "includes the address" do
      expect(mail_body).to include(
        "Address: 123 HIGH STREET, BIG CITY, AB3 4EF"
      )
    end

    it "includes the decision deadline" do
      expect(mail_body).to include("26 November 2022")
    end
  end

  describe "#validation_request_mail" do
    let(:validation_request_mail) do
      described_class.validation_request_mail(planning_application.reload, validation_request)
    end

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
      expect(validation_request_mail.body.encoded).to include("Application received: #{planning_application.received_at}")
      expect(validation_request_mail.body.encoded).to include(validation_request.user.name)
      expect(validation_request_mail.body.encoded).to include(validation_request.response_due.to_s)
      expect(validation_request_mail.body.encoded).to include(planning_application.change_access_id)
      expect(validation_request_mail.body.encoded).to include("http://cookies.example.com/validation_requests?planning_application_id=#{planning_application.id}&change_access_id=#{planning_application.change_access_id}")
      expect(validation_request_mail.body.encoded).to include("Cookie authority")
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

  describe "#cancelled_validation_request_mail" do
    let(:cancelled_validation_request_mail) do
      described_class.cancelled_validation_request_mail(planning_application.reload, validation_request)
    end

    it "emails only the agent when the agent is present" do
      expect(cancelled_validation_request_mail.to).to eq([planning_application.agent_email])
    end

    it "emails only the applicant when the agent is missing" do
      planning_application.update!(agent_email: "")
      mail = described_class.cancelled_validation_request_mail(planning_application.reload, validation_request)

      expect(mail.to).to eq([planning_application.applicant_email])
    end

    it "renders the headers" do
      expect(cancelled_validation_request_mail.subject).to eq("Your planning application at: #{planning_application.full_address}")
      expect(cancelled_validation_request_mail.to).to eq([planning_application.agent_email])
    end

    it "renders the body" do
      body = cancelled_validation_request_mail.body.encoded
      expect(body).to include("Application number: #{planning_application.reference_in_full}")
      expect(body).to include("Application received: #{planning_application.received_at}")
      expect(body).to include("At: #{planning_application.full_address}")
      expect(body).to include("Hi #{planning_application.agent_or_applicant_name}")
      expect(body).to include("#{validation_request.user.name}, the officer working on your planning application has cancelled one of the validation requests(s) on your application. You no longer need to take action for this request.")
      expect(body).to include("To see the reason this request was cancelled and review any remaining validation requests please follow the link below:")
      expect(body).to include(planning_application.change_access_id)
      expect(body).to include("http://cookies.example.com/validation_requests?planning_application_id=#{planning_application.id}&change_access_id=#{planning_application.change_access_id}")
      expect(body).to include("Yours faithfully")
      expect(body).to include(planning_application.local_authority.name.to_s)
    end

    it "includes the name of the agent in the body if agent is present" do
      expect(cancelled_validation_request_mail.body.encoded).to include(planning_application.agent_first_name)
      expect(cancelled_validation_request_mail.body.encoded).to include(planning_application.agent_last_name)
    end

    it "includes the name of the applicant in the body if no agent is present" do
      planning_application.update!(agent_first_name: "")
      mail = described_class.cancelled_validation_request_mail(planning_application.reload, validation_request)

      expect(mail.body.encoded).to include(planning_application.applicant_first_name)
      expect(mail.body.encoded).to include(planning_application.applicant_last_name)
    end
  end

  describe "#receipt_notice_mail" do
    let(:mail) do
      described_class.receipt_notice_mail(
        planning_application,
        planning_application.agent_email
      )
    end

    let(:mail_body) { mail.body.encoded }

    it "sets the subject" do
      expect(mail.subject).to eq(
        "Lawful Development Certificate application received"
      )
    end

    it "sets the recipients" do
      expect(mail.to).to contain_exactly("cookie_crackers@example.com")
    end

    it "includes the reference" do
      expect(mail_body).to include(
        "Application reference number: ABC-22-00100-LDCP"
      )
    end

    it "includes the description" do
      expect(mail_body).to include("Project description: Add a chimney stack")
    end

    it "includes the address" do
      expect(mail_body).to match("Address: 123 HIGH STREET, BIG CITY, AB3 4EF")
    end

    it "includes the sent date" do
      expect(mail_body).to include("Application sent: 1 May 2022")
    end

    it "includes the received date" do
      expect(mail_body).to include("Application received: 3 May 2022")
    end
  end

  context "creating description changes for an undetermined application" do
    let!(:undetermined_planning_application) do
      create :planning_application,
             local_authority: local_authority
    end

    let!(:description_change_request) do
      create :description_change_validation_request,
             planning_application: undetermined_planning_application,
             user: assessor
    end

    describe "#receipt_notice_mail" do
      let!(:description_change_mail) do
        described_class.description_change_mail(planning_application, description_change_request)
      end

      it "renders the headers" do
        expect(description_change_mail.subject).to eq("Your planning application at: #{planning_application.full_address}")
        expect(description_change_mail.to).to eq([planning_application.agent_email])
      end

      it "renders the body" do
        expect(description_change_mail.body.encoded).to match("Application number: #{planning_application.reference_in_full}")
        expect(description_change_mail.body.encoded).to match("Application received: #{planning_application.received_at}")
        expect(description_change_mail.body.encoded).to match("At: #{planning_application.full_address}")
        expect(description_change_mail.body.encoded).to match("the officer working on your planning application has proposed a change to the description of your application.")
        expect(description_change_mail.body.encoded).to match("If your response is not received by #{description_change_request.request_expiry_date}")
        expect(description_change_mail.body.encoded).to match("the proposed description will be automatically accepted as the description of your application.")
      end
    end

    describe "# description_closure_notification_mail" do
      let!(:description_closure_mail) do
        described_class.description_closure_notification_mail(planning_application, description_change_request)
      end

      it "renders the headers" do
        expect(description_closure_mail.subject).to eq("Your planning application at: #{planning_application.full_address}")
        expect(description_closure_mail.to).to eq([planning_application.agent_email])
      end

      it "renders the body" do
        expect(description_closure_mail.body.encoded).to match("Reference: #{planning_application.reference_in_full}")
        expect(description_closure_mail.body.encoded).to match("Site address: #{planning_application.full_address}")
        expect(description_closure_mail.body.encoded).to match("Description: #{planning_application.description}")
        expect(description_closure_mail.body.encoded).to match("The proposed description change which you were told about 5 business days ago has been automatically accepted.")
        expect(description_closure_mail.body.encoded).to match("To see the updated description please follow the link below:")
      end
    end
  end
end
