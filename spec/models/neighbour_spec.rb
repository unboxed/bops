# frozen_string_literal: true

require "rails_helper"

RSpec.describe Neighbour do
  describe "#valid?" do
    let(:neighbour) { build(:neighbour) }

    it "is true for factory" do
      expect(neighbour.valid?).to be(true)
    end
  end
end
