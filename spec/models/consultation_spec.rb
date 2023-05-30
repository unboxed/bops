# frozen_string_literal: true

require "rails_helper"

RSpec.describe Consultation do
  describe "#valid?" do
    let(:consultation) { build(:consultation) }

    it "is true for factory" do
      expect(consultation.valid?).to be(true)
    end
  end
end
