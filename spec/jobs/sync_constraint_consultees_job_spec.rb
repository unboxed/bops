# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncConstraintConsulteesJob, type: :job do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :published, local_authority:, api_user: create(:api_user, :planx)) }
  let!(:consultation) { planning_application.consultation || planning_application.create_consultation! }
  let(:constraint) { create(:constraint, local_authority:) }
  let!(:planning_constraint) do
    create(
      :planning_application_constraint,
      planning_application:,
      constraint:,
      identified: true,
      identified_by: "PlanX"
    )
  end
  let(:contact) do
    create(
      :contact,
      :external,
      local_authority:,
      name: "Historic England",
      email_address: "heritage@example.com"
    )
  end
  let!(:consultee_mapping) { ConsulteeConstraint.create!(constraint:, consultee: contact) }

  before { clear_enqueued_jobs }

  describe "#perform" do
    it "adds mapped consultees to each planning application constraint" do
      expect do
        described_class.perform_now(planning_constraint.id)
      end.to change { consultation.consultees.where(email_address: "heritage@example.com").count }.by(1)

      expect(planning_constraint.reload.consultees.pluck(:email_address)).to include("heritage@example.com")
    end

    it "does not duplicate records when rerun" do
      described_class.perform_now(planning_constraint.id)

      expect {
        described_class.perform_now(planning_constraint.id)
      }.not_to change { planning_constraint.reload.planning_application_constraint_consultees.count }
    end

    it "uses the latest mapping" do
      described_class.perform_now(planning_constraint.id)

      new_contact = create(
        :contact,
        :external,
        local_authority:,
        name: "Environment Agency",
        email_address: "environment@example.com"
      )
      ConsulteeConstraint.create!(constraint:, consultee: new_contact)

      described_class.perform_now(planning_constraint.id)

      expect(planning_constraint.reload.consultees.pluck(:email_address))
        .to match_array(["environment@example.com", "heritage@example.com"])
    end
  end
end
