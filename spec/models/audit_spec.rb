# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audit, type: :model do
  describe "validations" do
    subject(:audit) { described_class.new }

    describe "#activity_type" do
      it "validates presence" do
        expect { audit.valid? }.to change { audit.errors[:activity_type] }.to ["can't be blank"]
      end
    end

    describe "#planning_application" do
      it "validates presence" do
        expect { audit.valid? }.to change { audit.errors[:planning_application] }.to ["must exist"]
      end
    end
  end
end
