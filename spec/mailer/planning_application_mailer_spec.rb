# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationMailer, type: :mailer do
  let(:local_authority) do
    create(
      :local_authority,
      :default,
      signatory_name: "Mr. Biscuit",
      signatory_job_title: "Lord of BiscuitTown",
      enquiries_paragraph: "reach us on postcode SW50",
      email_address: "biscuit@somuchbiscuit.com"
    )
  end

  let!(:reviewer) { create(:user, :reviewer, local_authority:) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }
  let(:application_type) { create(:application_type) }

  let(:planning_application) do
    create(
      :planning_application,
      :determined,
      agent_email: "cookie_crackers@example.com",
      applicant_email: "cookie_crumbs@example.com",
      local_authority:,
      decision: "granted",
      address_1: "123 High Street",
      town: "Big City",
      postcode: "AB3 4EF",
      description: "Add a chimney stack",
      created_at: DateTime.new(2022, 5, 1),
      application_type:,
      validated_at: DateTime.new(2022, 10, 1)
    )
  end

  let(:invalid_planning_application) do
    create(:planning_application, :invalidated)
  end

  let(:host) { "planx.example.com" }

  let(:validation_request) do
    create(:other_change_validation_request, planning_application: invalid_planning_application, user: assessor)
  end

  let(:document_with_tags) do
    create(:document, :with_tags,
           planning_application:,
           numbers: "proposed_number_1, proposed_number_2",
           referenced_in_decision_notice: true)
  end

  let(:archived_document_with_tags) do
    create(:document, :archived, :with_tags,
           planning_application:,
           numbers: "archived_number")
  end

  before do
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with("APPLICANTS_APP_HOST").and_return("example.com")
  end

  describe "#decision_notice_mail" do
    let(:mail) do
      described_class.decision_notice_mail(
        planning_application,
        host,
        planning_application.applicant_email
      )
    end

    let(:mail_body) { mail.body.encoded }

    it "sets the subject" do
      expect(mail.subject).to eq(
        "Decision on your Lawful Development Certificate application"
      )
    end

    it "sets the recipient" do
      expect(mail.to).to contain_exactly("cookie_crumbs@example.com")
    end

    it "includes the reference" do
      travel_to("2022-01-01") do
        expect(mail_body).to include(
          "Application reference number: PlanX-22-00100-LDCP"
        )
      end
    end

    it "includes the address" do
      expect(mail_body).to include(
        "Address: 123 High Street, Big City, AB3 4EF"
      )
    end

    it "includes the decision" do
      expect(mail_body).to include(
        "a decision has been made to grant you a Lawful Development Certificate"
      )
    end

    it "includes a link to the decision notice" do
      expect(mail_body).to include(
        "http://planx.example.com/api/v1/planning_applications/#{planning_application.id}/decision_notice.pdf"
      )
    end

    context "with a rejected application" do
      let(:planning_application) do
        create(
          :planning_application,
          :determined,
          decision: "refused",
          public_comment: "not valid"
        )
      end

      it "includes the decision" do
        expect(mail_body).to include(
          "your application for a Lawful Development Certificate has been refused"
        )
      end

      it "includes a link to the decision notice" do
        expect(mail_body).to include(
          "http://planx.example.com/api/v1/planning_applications/#{planning_application.id}/decision_notice.pdf"
        )
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
    let(:planning_application) do
      create(
        :planning_application,
        :invalidated,
        local_authority:,
        address_1: "123 High Street",
        town: "Big City",
        postcode: "AB3 4EF",
        invalidated_at: DateTime.new(2022, 6, 5)
      )
    end

    let(:validation_request) do
      create(:other_change_validation_request, planning_application:, user: assessor)
    end

    let(:invalidation_mail) do
      described_class.invalidation_notice_mail(planning_application)
    end

    let(:mail_body) { invalidation_mail.body.encoded }

    it "emails only the agent when the agent is present" do
      expect(invalidation_mail.to).to eq([planning_application.agent_email])
    end

    it "emails only the applicant when the agent is missing" do
      planning_application.update!(agent_email: "")
      mail = described_class.invalidation_notice_mail(planning_application.reload)

      expect(mail.to).to eq([planning_application.applicant_email])
    end

    it "sets the subject" do
      expect(invalidation_mail.subject).to eq(
        "Lawful Development Certificate application - changes needed"
      )
    end

    it "includes the reference" do
      travel_to("2022-01-01") do
        expect(mail_body).to include(
          "Application reference number: PlanX-22-00100-LDCP"
        )
      end
    end

    it "includes the address" do
      expect(mail_body).to include("Address: 123 High Street, Big City, AB3 4EF")
    end

    it "includes the validation request url" do
      expect(mail_body).to include(
        "http://planx.example.com/validation_requests?planning_application_id=#{planning_application.id}&change_access_id=#{planning_application.change_access_id}"
      )
    end

    it "includes the invalidation response due date" do
      expect(mail_body).to include("27 June 2022")
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
      travel_to("2022-01-01") do
        expect(mail_body).to include(
          "Application reference number: PlanX-22-00100-LDCP"
        )
      end
    end

    it "includes the address" do
      expect(mail_body).to include(
        "Address: 123 High Street, Big City, AB3 4EF"
      )
    end

    it "includes the decision deadline" do
      expect(mail_body).to include("26 November 2022")
    end
  end

  describe "#validation_request_mail" do
    let(:validation_request_mail) do
      described_class.validation_request_mail(planning_application)
    end

    let(:mail_body) { validation_request_mail.body.encoded }

    it "emails only the agent when the agent is present" do
      expect(validation_request_mail.to).to eq([planning_application.agent_email])
    end

    it "emails only the applicant when the agent is missing" do
      planning_application.update!(agent_email: "")
      mail = described_class.validation_request_mail(planning_application)

      expect(mail.to).to eq([planning_application.applicant_email])
    end

    it "sets the subject" do
      expect(validation_request_mail.subject).to eq(
        "Lawful Development Certificate application - further changes needed"
      )
    end

    it "sets the recipient" do
      expect(validation_request_mail.to).to contain_exactly(
        "cookie_crackers@example.com"
      )
    end

    it "includes the reference" do
      travel_to("2022-01-01") do
        expect(mail_body).to include(
          "Application reference number: PlanX-22-00100-LDCP"
        )
      end
    end

    it "includes the address" do
      expect(mail_body).to include(
        "Address: 123 High Street, Big City, AB3 4EF"
      )
    end

    it "includes the validation request url" do
      expect(mail_body).to include(
        "http://planx.example.com/validation_requests?planning_application_id=#{planning_application.id}&change_access_id=#{planning_application.change_access_id}"
      )
    end

    it "includes the name of the agent in the body if agent is present" do
      expect(validation_request_mail.body.encoded).to include(planning_application.agent_first_name)
      expect(validation_request_mail.body.encoded).to include(planning_application.agent_last_name)
    end

    it "includes the name of the applicant in the body if no agent is present" do
      planning_application.update!(agent_first_name: "")
      mail = described_class.validation_request_mail(planning_application.reload)

      expect(mail.body.encoded).to include(planning_application.applicant_first_name)
      expect(mail.body.encoded).to include(planning_application.applicant_last_name)
    end
  end

  describe "#post_validation_request_mail" do
    let!(:validation_request) do
      create(:red_line_boundary_change_validation_request, planning_application: invalid_planning_application,
                                                           user: assessor)
    end
    let(:post_validation_request_mail) do
      described_class.post_validation_request_mail(planning_application, validation_request)
    end

    let(:mail_body) { post_validation_request_mail.body.encoded }

    context "when agent is present" do
      it "emails only the agent when the agent is present" do
        expect(post_validation_request_mail.to).to eq([planning_application.agent_email])
      end

      it "includes the name of the agent in the body" do
        expect(mail_body).to include(planning_application.agent_first_name)
        expect(mail_body).to include(planning_application.agent_last_name)
      end
    end

    context "when agent is missing" do
      before do
        planning_application.update!(agent_email: "")
        planning_application.update!(agent_first_name: "")
      end

      it "emails only the applicant when the agent is missing" do
        mail = described_class.post_validation_request_mail(planning_application, validation_request)

        expect(mail.to).to eq([planning_application.applicant_email])
      end

      it "includes the name of the applicant in the body" do
        mail = described_class.post_validation_request_mail(planning_application.reload, validation_request)

        expect(mail.body.encoded).to include(planning_application.applicant_first_name)
        expect(mail.body.encoded).to include(planning_application.applicant_last_name)
      end
    end

    context "when there is an assigned officer to the case" do
      before do
        planning_application.user = assessor
      end

      it "includes the information about the validation request being auto accepted" do
        expect(mail_body).to include(
          "#{planning_application.user.name}, the officer working on your planning application, has proposed a change to your application."
        )
      end
    end

    context "when there is no assigned officer to the case" do
      it "includes the information about the validation request being auto accepted" do
        expect(mail_body).to include(
          "The officer working on your planning application, has proposed a change to your application."
        )
      end
    end

    it "sets the subject" do
      expect(post_validation_request_mail.subject).to eq(
        "Lawful Development Certificate application - changes needed"
      )
    end

    it "sets the recipient" do
      expect(post_validation_request_mail.to).to contain_exactly(
        "cookie_crackers@example.com"
      )
    end

    it "includes the reference" do
      travel_to("2022-01-01") do
        expect(mail_body).to include(
          "Application number: PlanX-22-00100-LDCP"
        )
      end
    end

    it "includes the application received at date" do
      expect(mail_body).to include(
        "Application received: 3 May 2022"
      )
    end

    it "includes the address" do
      expect(mail_body).to include(
        "At: 123 High Street, Big City, AB3 4EF"
      )
    end

    it "includes the validation request url" do
      expect(mail_body).to include(
        "http://planx.example.com/validation_requests?planning_application_id=#{planning_application.id}&change_access_id=#{planning_application.change_access_id}"
      )
    end

    it "includes the information about the validation request being auto accepted" do
      expect(mail_body).to include(
        "If your response is not received by #{validation_request.request_expiry_date.to_fs}, the proposed changes to your application will be automatically accepted."
      )
      expect(mail_body).to include(
        "This is to avoid delays in making a determination on your application."
      )
    end
  end

  describe "#cancelled_validation_request_mail" do
    let(:cancelled_validation_request_mail) do
      described_class.cancelled_validation_request_mail(planning_application)
    end

    let(:mail_body) { cancelled_validation_request_mail.body.encoded }

    it "emails only the agent when the agent is present" do
      expect(cancelled_validation_request_mail.to).to eq([planning_application.agent_email])
    end

    it "emails only the applicant when the agent is missing" do
      planning_application.update!(agent_email: "")
      mail = described_class.cancelled_validation_request_mail(planning_application.reload)

      expect(mail.to).to eq([planning_application.applicant_email])
    end

    it "sets subject" do
      expect(cancelled_validation_request_mail.subject).to eq(
        "Update on your application for a Lawful Development Certificate"
      )
    end

    it "sets recipient" do
      expect(cancelled_validation_request_mail.to).to contain_exactly(
        "cookie_crackers@example.com"
      )
    end

    it "includes the reference" do
      travel_to("2022-01-01") do
        expect(mail_body).to include("Application number: PlanX-22-00100-LDCP")
      end
    end

    it "includes the address" do
      expect(mail_body).to include("Address: 123 High Street, Big City, AB3 4EF")
    end

    it "includes the validation request url" do
      expect(mail_body).to include(
        "http://planx.example.com/validation_requests?planning_application_id=#{planning_application.id}&change_access_id=#{planning_application.change_access_id}"
      )
    end

    it "includes the name of the agent in the body if agent is present" do
      expect(cancelled_validation_request_mail.body.encoded).to include(planning_application.agent_first_name)
      expect(cancelled_validation_request_mail.body.encoded).to include(planning_application.agent_last_name)
    end

    it "includes the name of the applicant in the body if no agent is present" do
      planning_application.update!(agent_first_name: "")
      mail = described_class.cancelled_validation_request_mail(planning_application.reload)

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
      travel_to("2022-01-01") do
        expect(mail_body).to include(
          "Application reference number: PlanX-22-00100-LDCP"
        )
      end
    end

    it "includes the description" do
      expect(mail_body).to include("Project description: Add a chimney stack")
    end

    it "includes the address" do
      expect(mail_body).to match("Address: 123 High Street, Big City, AB3 4EF")
    end

    it "includes the sent date" do
      expect(mail_body).to include("Application sent: 1 May 2022")
    end

    it "includes the received date" do
      expect(mail_body).to include("Application received: 3 May 2022")
    end
  end

  context "when creating description changes for an undetermined application" do
    let(:planning_application) do
      create(
        :planning_application,
        agent_email: "agent@example.com",
        local_authority:,
        address_1: "123 High Street",
        town: "Big City",
        postcode: "AB3 4EF"
      )
    end

    let(:description_change_request) do
      create(
        :description_change_validation_request,
        planning_application:,
        user: assessor,
        created_at: DateTime.new(2022, 5, 10)
      )
    end

    describe "#description_change_mail" do
      let(:description_change_mail) do
        described_class.description_change_mail(
          planning_application,
          description_change_request
        )
      end

      let(:mail_body) { description_change_mail.body.encoded }

      it "sets the subject" do
        expect(description_change_mail.subject).to eq(
          "Lawful Development Certificate application - suggested changes"
        )
      end

      it "sets the recipient" do
        expect(description_change_mail.to).to contain_exactly(
          "agent@example.com"
        )
      end

      it "includes the reference" do
        travel_to("2022-01-01") do
          expect(mail_body).to include(
            "Application reference number: PlanX-22-00100-LDCP"
          )
        end
      end

      it "includes the address" do
        expect(mail_body).to include(
          "Address: 123 High Street, Big City, AB3 4EF"
        )
      end

      it "includes the validation request url" do
        expect(mail_body).to include(
          "http://planx.example.com/validation_requests?planning_application_id=#{planning_application.id}&change_access_id=#{planning_application.change_access_id}"
        )
      end

      it "includes the request expiry date" do
        expect(mail_body).to include("17 May 2022")
      end
    end

    describe "#description_closure_notification_mail" do
      let(:description_closure_mail) do
        described_class.description_closure_notification_mail(
          planning_application,
          description_change_request
        )
      end

      let(:mail_body) { description_closure_mail.body.encoded }

      it "sets the subject" do
        expect(description_closure_mail.subject).to eq(
          "Changes to your Lawful Development Certificate application"
        )
      end

      it "sets the recipient" do
        expect(description_closure_mail.to).to contain_exactly(
          "agent@example.com"
        )
      end

      it "includes the reference" do
        travel_to("2022-01-01") do
          expect(mail_body).to include(
            "Application reference number: PlanX-22-00100-LDCP"
          )
        end
      end

      it "includes the address" do
        expect(mail_body).to include(
          "Address: 123 High Street, Big City, AB3 4EF"
        )
      end

      it "includes the review deadline" do
        expect(mail_body).to include("17 May 2022")
      end

      it "includes the validation request url" do
        expect(mail_body).to include(
          "http://planx.example.com/validation_requests?planning_application_id=#{planning_application.id}&change_access_id=#{planning_application.change_access_id}"
        )
      end
    end
  end

  describe "#validation_request_closure_mail" do
    let(:validation_request_closure_mail) do
      described_class.validation_request_closure_mail(planning_application)
    end

    let(:mail_body) { validation_request_closure_mail.body.encoded }

    it "emails only the agent when the agent is present" do
      expect(validation_request_closure_mail.to).to eq([planning_application.agent_email])
    end

    it "emails only the applicant when the agent is missing" do
      planning_application.update!(agent_email: "")
      mail = described_class.validation_request_closure_mail(planning_application)

      expect(mail.to).to eq([planning_application.applicant_email])
    end

    it "sets the subject" do
      expect(validation_request_closure_mail.subject).to eq(
        "Changes to your Lawful Development Certificate application"
      )
    end

    it "sets the recipient" do
      expect(validation_request_closure_mail.to).to contain_exactly(
        "cookie_crackers@example.com"
      )
    end

    it "includes the reference" do
      travel_to("2022-01-01") do
        expect(mail_body).to include(
          "Application reference number: PlanX-22-00100-LDCP"
        )
      end
    end

    it "includes the address" do
      expect(mail_body).to include(
        "At: 123 High Street, Big City, AB3 4EF"
      )
    end

    it "includes the main text body" do
      expect(mail_body).to include(
        "A proposed change to your application which you were told about 5 days ago has been automatically accepted as we have not had a response from you."
      )
    end

    it "includes the validation request url" do
      expect(mail_body).to include(
        "http://planx.example.com/validation_requests?planning_application_id=#{planning_application.id}&change_access_id=#{planning_application.change_access_id}"
      )
    end

    it "includes the response email" do
      expect(mail_body).to include(
        "If you have any questions, send them to #{planning_application.local_authority.email_address} and someone will get back to you."
      )
    end

    it "includes the name of the agent in the body if agent is present" do
      expect(validation_request_closure_mail.body.encoded).to include(planning_application.agent_first_name)
      expect(validation_request_closure_mail.body.encoded).to include(planning_application.agent_last_name)
    end

    it "includes the name of the applicant in the body if no agent is present" do
      planning_application.update!(agent_first_name: "")
      mail = described_class.validation_request_closure_mail(planning_application.reload)

      expect(mail.body.encoded).to include(planning_application.applicant_first_name)
      expect(mail.body.encoded).to include(planning_application.applicant_last_name)
    end
  end

  describe "#neighbour_consultation_letter_copy_mail" do
    let!(:consultation) do
      travel_to("2022-01-01") { create(:consultation, planning_application:) }
    end

    let(:application_type) { create(:application_type, :prior_approval) }

    let(:planning_application) do
      create(
        :planning_application,
        :determined,
        agent_email: "cookie_crackers@example.com",
        applicant_email: "cookie_crumbs@example.com",
        local_authority:,
        decision: "granted",
        address_1: "123 High Street",
        town: "Big City",
        postcode: "AB3 4EF",
        description: "Add a chimney stack",
        created_at: DateTime.new(2022, 5, 1),
        application_type:,
        validated_at: DateTime.new(2022, 10, 1)
      )
    end

    let(:neighbour_consultation_letter_copy_mail) do
      described_class.neighbour_consultation_letter_copy_mail(planning_application, planning_application.agent_email)
    end

    let(:mail_body) { neighbour_consultation_letter_copy_mail.body.encoded }

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("BOPS_ENVIRONMENT", "development").and_return("production")

      consultation.update(neighbour_letter_text: consultation.neighbour_letter_content)
    end

    it "sets the subject" do
      expect(neighbour_consultation_letter_copy_mail.subject).to eq(
        "Neighbour consultation letter copy"
      )
    end

    it "sets the recipient" do
      expect(neighbour_consultation_letter_copy_mail.to).to contain_exactly(
        "cookie_crackers@example.com"
      )
    end

    it "includes the reference" do
      expect(mail_body).to include(
        "Application reference number: PlanX-22-00100-PA"
      )
    end

    it "includes the address" do
      expect(mail_body).to include(
        "At: 123 High Street, Big City, AB3 4EF"
      )
    end

    it "includes the main text body" do
      expect(mail_body).to include(
        "This is a copy of your neighbour consultation letter."
      )
      expect(mail_body).to include(
        "Submit your comments by #{(1.business_day.from_now + 21.days).to_date.to_fs(:day_month_year)}"
      )
      expect(mail_body).to include(
        "A prior approval application has been made for the development described below:"
      )
      expect(mail_body).to include(
        "https://planningapplications.planx.gov.uk/planning_applications/#{planning_application.id}"
      )
    end

    it "includes the name of the agent in the body if agent is present" do
      expect(neighbour_consultation_letter_copy_mail.body.encoded).to include(planning_application.agent_first_name)
      expect(neighbour_consultation_letter_copy_mail.body.encoded).to include(planning_application.agent_last_name)
    end
  end

  context "when the application is a prior approval" do
    let(:application_type) { create(:application_type, name: "prior_approval") }

    let(:planning_application) do
      create(
        :planning_application,
        :determined,
        :from_planx_prior_approval,
        agent_email: "cookie_crackers@example.com",
        applicant_email: "cookie_crumbs@example.com",
        local_authority:,
        decision: "granted",
        address_1: "123 High Street",
        town: "Big City",
        postcode: "AB3 4EF",
        description: "Add a chimney stack",
        created_at: DateTime.new(2022, 5, 1),
        application_type:,
        validated_at: DateTime.new(2022, 10, 1)
      )
    end

    describe "#decision_notice_mail" do
      let(:mail) do
        described_class.decision_notice_mail(
          planning_application,
          host,
          planning_application.applicant_email
        )
      end

      let(:mail_body) { mail.body.encoded }

      it "sets the subject" do
        expect(mail.subject).to eq(
          "Decision on your Prior approval application"
        )
      end

      it "includes the decision" do
        expect(mail_body).to include(
          "a decision has been made to grant you a Prior approval"
        )
      end

      context "with a rejected application" do
        let(:planning_application) do
          create(
            :planning_application,
            :determined,
            :from_planx_prior_approval,
            decision: "refused",
            application_type:,
            public_comment: "not valid"
          )
        end

        it "includes the decision" do
          expect(mail_body).to include(
            "your application for a Prior approval has been refused"
          )
        end
      end
    end

    describe "#invalidation_notice_mail" do
      let(:planning_application) do
        create(
          :planning_application,
          :invalidated,
          :from_planx_prior_approval,
          local_authority:,
          application_type:,
          address_1: "123 High Street",
          town: "Big City",
          postcode: "AB3 4EF",
          invalidated_at: DateTime.new(2022, 6, 5)
        )
      end

      let(:validation_request) do
        create(:other_change_validation_request, planning_application:, user: assessor)
      end

      let(:invalidation_mail) do
        described_class.invalidation_notice_mail(planning_application)
      end

      let(:mail_body) { invalidation_mail.body.encoded }

      it "sets the subject" do
        expect(invalidation_mail.subject).to eq(
          "Prior approval application - changes needed"
        )
      end

      it "includes the application type" do
        expect(mail_body).to include("Prior approval")
        expect(mail_body).not_to include("Lawful Development Certificate")
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
          "Your application for a Prior approval"
        )
      end

      it "includes the application type" do
        expect(mail_body).to include("Prior approval")
        expect(mail_body).not_to include("Lawful Development Certificate")
      end
    end

    describe "#validation_request_mail" do
      let(:validation_request_mail) do
        described_class.validation_request_mail(planning_application)
      end
      let(:mail_body) { validation_request_mail.body.encoded }

      it "sets the subject" do
        expect(validation_request_mail.subject).to eq(
          "Prior approval application - further changes needed"
        )
      end

      it "includes the application type" do
        expect(mail_body).to include("Prior approval")
        expect(mail_body).not_to include("Lawful Development Certificate")
      end
    end

    describe "#post_validation_request_mail" do
      let!(:validation_request) do
        create(:red_line_boundary_change_validation_request, planning_application: invalid_planning_application,
                                                             user: assessor)
      end
      let(:post_validation_request_mail) do
        described_class.post_validation_request_mail(planning_application, validation_request)
      end

      it "sets the subject" do
        expect(post_validation_request_mail.subject).to eq(
          "Prior approval application - changes needed"
        )
      end
    end

    describe "#cancelled_validation_request_mail" do
      let(:cancelled_validation_request_mail) do
        described_class.cancelled_validation_request_mail(planning_application)
      end

      it "sets subject" do
        expect(cancelled_validation_request_mail.subject).to eq(
          "Update on your application for a Prior approval"
        )
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
          "Prior approval application received"
        )
      end

      it "includes the application type" do
        expect(mail_body).to include("Prior approval")
        expect(mail_body).not_to include("Lawful Development Certificate")
      end
    end

    context "when creating description changes for an undetermined application" do
      let(:planning_application) do
        create(
          :planning_application,
          :from_planx_prior_approval,
          application_type:,
          agent_email: "agent@example.com",
          local_authority:,
          address_1: "123 High Street",
          town: "Big City",
          postcode: "AB3 4EF"
        )
      end

      let(:description_change_request) do
        create(
          :description_change_validation_request,
          planning_application:,
          user: assessor,
          created_at: DateTime.new(2022, 5, 10)
        )
      end

      describe "#description_change_mail" do
        let(:description_change_mail) do
          described_class.description_change_mail(
            planning_application,
            description_change_request
          )
        end

        let(:mail_body) { description_change_mail.body.encoded }

        it "sets the subject" do
          expect(description_change_mail.subject).to eq(
            "Prior approval application - suggested changes"
          )
        end

        it "includes the application type" do
          expect(mail_body).to include("Prior approval")
          expect(mail_body).not_to include("Lawful Development Certificate")
        end
      end

      describe "#description_closure_notification_mail" do
        let(:description_closure_mail) do
          described_class.description_closure_notification_mail(
            planning_application,
            description_change_request
          )
        end

        let(:mail_body) { description_closure_mail.body.encoded }

        it "sets the subject" do
          expect(description_closure_mail.subject).to eq(
            "Changes to your Prior approval application"
          )
        end

        it "includes the application type" do
          expect(mail_body).to include("Prior approval")
          expect(mail_body).not_to include("Lawful Development Certificate")
        end
      end
    end

    describe "#validation_request_closure_mail" do
      let(:validation_request_closure_mail) do
        described_class.validation_request_closure_mail(planning_application)
      end

      it "sets the subject" do
        expect(validation_request_closure_mail.subject).to eq(
          "Changes to your Prior approval application"
        )
      end
    end
  end
end
