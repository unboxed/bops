# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Application::SubmissionRedactionService, type: :service do
  describe "#call!" do
    let!(:local_authority) { create(:local_authority) }

    let(:redact_submission) do
      described_class.new(planning_application:).call
    end

    let(:submission) { JSON.parse(BopsApi::Engine.root.join("spec", "fixtures", "examples", "odp", "v0.6.0", "validPlanningPermission.json").read) }
    let(:planx_planning_data) { create(:planx_planning_data, params_v2: submission) }
    let(:planning_application) { create(:planning_application, local_authority:, planx_planning_data:) }

    it "redacts the personal contact information on the submission" do
      described_class::FIELDS_TO_REDACT.each do |field_path|
        next unless (value = redact_submission.dig(*field_path))

        expect(value).to eq("REDACTED")
      end
    end
  end
end
