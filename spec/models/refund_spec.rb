# frozen_string_literal: true

require "rails_helper"

RSpec.describe Refund, type: :model do
  let(:refund) { create(:refund) }

  describe "validations" do
    subject(:refund) { described_class.new }

    describe "#payment_type" do
      it "validates presence" do
        expect { refund.valid? }.to change { refund.errors[:payment_type] }.to ["can't be blank"]
      end
    end

    describe "#amount" do
      it "validates presence" do
        expect { refund.valid? }.to change { refund.errors[:amount] }.to ["can't be blank"]
      end
    end

    describe "#reason" do
      it "validates presence" do
        expect { refund.valid? }.to change { refund.errors[:reason] }.to ["can't be blank"]
      end
    end

    describe "#date" do
      it "validates presence" do
        expect { refund.valid? }.to change { refund.errors[:date] }.to ["can't be blank"]
      end
    end
  end
end
