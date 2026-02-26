# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationConstraint do
  describe "validations" do
    subject(:planning_application_constraint) { described_class.new }

    describe "#constraint" do
      it "validates presence" do
        expect { planning_application_constraint.valid? }.to change { planning_application_constraint.errors[:constraint] }.to ["must exist"]
      end
    end

    describe "#planning_application" do
      it "validates presence" do
        expect { planning_application_constraint.valid? }.to change { planning_application_constraint.errors[:planning_application] }.to ["must exist"]
      end
    end
  end

  describe "#added?" do
    it "returns true" do
      expect(described_class.new.added?).to be true
    end
  end

  describe "callbacks" do
    let(:local_authority) { create(:local_authority, :default) }
    let(:planning_application) { create(:planning_application, :published, local_authority:, api_user: create(:api_user, :planx)) }
    let(:consultation) { planning_application.consultation || planning_application.create_consultation! }
    let(:constraint) { create(:constraint) }
    let(:contact) do
      create(
        :contact,
        :external,
        local_authority:,
        name: "Historic England",
        email_address: "heritage@example.com"
      )
    end

    before do
      ConsulteeConstraint.create!(consultee: contact, constraint:)
    end

    before { clear_enqueued_jobs }

    it "enqueues a sync job" do
      expect do
        described_class.create!(
          planning_application:,
          constraint:,
          identified: true,
          identified_by: "PlanX"
        )
      end.to have_enqueued_job(SyncConstraintConsulteesJob).with(a_kind_of(Integer))
    end

    it "creates consultees for mapped contacts" do
      expect do
        perform_enqueued_jobs do
          described_class.create!(
            planning_application:,
            constraint:,
            identified: true,
            identified_by: "PlanX"
          )
        end
      end.to change { consultation.consultees.where(email_address: "heritage@example.com").count }.by(1)

      planning_constraint = described_class.last
      expect(planning_constraint.consultees.pluck(:email_address)).to include("heritage@example.com")
    end

    it "reuses existing consultees instead of duplicating them" do
      existing_consultee = consultation.consultees.create!(
        name: "Historic England",
        email_address: "heritage@example.com",
        origin: contact.origin
      )

      planning_constraint = perform_enqueued_jobs do
        described_class.create!(
          planning_application:,
          constraint:,
          identified: true,
          identified_by: "PlanX"
        )
      end

      expect(consultation.consultees.where(email_address: "heritage@example.com").count).to eq(1)
      expect(planning_constraint.consultees).to include(existing_consultee)
    end
  end
end
