# frozen_string_literal: true

require "rails_helper"

RSpec.describe Policy, type: :model do
  describe "#valid?" do
    let(:policy) { build(:policy) }

    it "is true for factory" do
      expect(policy.valid?).to eq(true)
    end
  end

  describe ".complies" do
    before do
      create(:policy, :does_not_comply)
      create(:policy, :to_be_determined)
    end

    let!(:policy) { create(:policy, :complies) }

    it "returns policies with status of 'complies'" do
      expect(described_class.complies).to contain_exactly(policy)
    end
  end

  describe ".does_not_comply" do
    before do
      create(:policy, :complies)
      create(:policy, :to_be_determined)
    end

    let!(:policy) { create(:policy, :does_not_comply) }

    it "returns policies with status of 'does_not_comply'" do
      expect(described_class.does_not_comply).to contain_exactly(policy)
    end
  end

  describe ".to_be_determined" do
    before do
      create(:policy, :does_not_comply)
      create(:policy, :complies)
    end

    let!(:policy) { create(:policy, :to_be_determined) }

    it "returns policies with status of 'to_be_determined'" do
      expect(described_class.to_be_determined).to contain_exactly(policy)
    end
  end
end
