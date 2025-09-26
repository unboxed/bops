# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationConstraintConsultee, type: :model do
  subject(:constraint_consultee) do
    described_class.new(planning_application_constraint:, consultee:)
  end

  let(:planning_application) { create(:planning_application) }
  let(:consultation) { create(:consultation, planning_application:) }
  let(:consultee) { create(:consultee, consultation:) }
  let(:planning_application_constraint) { create(:planning_application_constraint, planning_application:) }

  it { is_expected.to belong_to(:planning_application_constraint) }
  it { is_expected.to belong_to(:consultee) }

  it "validates uniqueness of consultee scoped to the constraint" do
    described_class.create!(planning_application_constraint:, consultee:)

    expect(constraint_consultee).not_to be_valid
    expect(constraint_consultee.errors[:consultee_id]).to include("has already been taken")
  end
end
