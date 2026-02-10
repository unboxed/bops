# frozen_string_literal: true

require "rails_helper"

RSpec.describe Refund, type: :model do
  let(:refund) { create(:refund) }

  describe "validations" do
    subject(:refund) { described_class.new }

    describe "#payment_type" do
      it "validates presence" do
        expect { refund.valid? }.to change { refund.errors[:payment_type] }.to ["Enter Payment type"]
      end
    end

    describe "#amount" do
      it "validates presence" do
        expect { refund.valid? }.to change { refund.errors[:amount] }.to ["Enter Amount"]
      end
    end

    describe "#reason" do
      it "validates presence" do
        expect { refund.valid? }.to change { refund.errors[:reason] }.to ["Enter Reason"]
      end
    end

    describe "#date" do
      it "validates presence" do
        expect { refund.valid? }.to change { refund.errors[:date] }.to ["Enter Date"]
      end
    end
  end
end
