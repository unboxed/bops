# frozen_string_literal: true

require "rails_helper"

RSpec.describe LandOwner do
  describe "validations" do
    subject(:land_owner) { described_class.new }

    describe "#name" do
      it "validates presence" do
        expect do
          land_owner.valid?
        end.to change {
          land_owner.errors[:name]
        }.to ["can't be blank"]
      end
    end
  end
end
