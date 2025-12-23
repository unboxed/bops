# frozen_string_literal: true

require_relative "../../swagger_helper"

RSpec.describe BopsSubmissions::Application::OdpCreationService, type: :service do
  describe "#call!" do
    let(:local_authority) { create(:local_authority) }
    let!(:application_type_pp) { create(:application_type, :planning_permission) }
    let(:api_user) { create(:api_user, :planx, local_authority:) }

    subject(:create_planning_application) do
      described_class.new(
        submission:,
        user: api_user,
        email_sending_permitted:
      ).call!
    end

    let(:email_sending_permitted) { false }

    around do |example|
      travel_to("2023-12-13") { example.run }
    end

    context "when submission contains valid ODP planning application JSON" do
      let(:submission) do
        create(:submission, :odp_planning_application, local_authority:)
      end

      before do
        ActiveJob::Base.queue_adapter = :test
      end

      it "creates a new planning application with expected attributes" do
        expect { create_planning_application }.to change(PlanningApplication, :count).by(1)

        pa = PlanningApplication.last
        expect(pa).to have_attributes(
          status: "pending",
          applicant_first_name: "David",
          applicant_last_name: "Bowie",
          applicant_email: "ziggy@example.com",
          agent_first_name: "Ziggy",
          agent_last_name: "Stardust",
          agent_email: "ziggy@example.com",
          local_authority_id: local_authority.id,
          api_user_id: api_user.id
        )
      end

      it "links the case record to the submission" do
        create_planning_application

        pa = PlanningApplication.last
        expect(pa.case_record).to be_present
        expect(pa.case_record.submission).to eq(submission)
      end

      it "enqueues the PlanningApplicationDependencyJob" do
        create_planning_application

        expect(BopsApi::PlanningApplicationDependencyJob).to have_been_enqueued.with(
          planning_application: PlanningApplication.last,
          user: api_user,
          files: submission.request_body.with_indifferent_access[:files],
          params: submission.request_body.with_indifferent_access,
          email_sending_permitted: false
        )
      end

      context "when email_sending_permitted is true" do
        let(:email_sending_permitted) { true }

        it "passes email_sending_permitted to the dependency job" do
          create_planning_application

          expect(BopsApi::PlanningApplicationDependencyJob).to have_been_enqueued.with(
            hash_including(email_sending_permitted: true)
          )
        end
      end
    end

    context "when submission is from BOPS production" do
      let(:submission) do
        create(:submission, :odp_planning_application, local_authority:).tap do |s|
          body = s.request_body.deep_dup
          body["metadata"] ||= {}
          body["metadata"]["source"] = "BOPS production"
          s.update!(request_body: body)
        end
      end

      it "sets from_production to true on the planning application" do
        create_planning_application

        pa = PlanningApplication.last
        expect(pa.from_production).to be true
      end
    end

    context "when submission has missing required data" do
      let(:submission) do
        create(:submission, local_authority:, request_body: {data: {}, files: []})
      end

      it "raises an error" do
        expect { create_planning_application }.to raise_error(StandardError)
      end
    end
  end
end
