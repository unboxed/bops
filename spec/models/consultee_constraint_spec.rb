# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConsulteeConstraint, type: :model do
  let(:local_authority) { create(:local_authority, :default) }
  let(:consultee) { create(:contact, :external, local_authority:) }
  let(:constraint) { create(:constraint, local_authority:) }

  subject(:consultee_constraint) do
    described_class.new(consultee:, constraint:)
  end

  it "is valid with a consultee and constraint" do
    expect(consultee_constraint).to be_valid
  end

  it "requires the consultee to have a consultee category" do
    consultee_constraint.consultee.category = nil

    expect(consultee_constraint).to be_invalid
    expect(consultee_constraint.errors[:consultee]).to include("is invalid")
  end

  it "prevents duplicate mappings" do
    existing = described_class.create!(consultee:, constraint:)

    duplicate = described_class.new(consultee: existing.consultee, constraint: existing.constraint)

    expect(duplicate).to be_invalid
    expect(duplicate.errors[:constraint_id]).to include("has already been taken")
  end
end
