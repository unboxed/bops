# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payment, type: :model do
  describe "validations" do
    let(:charge) { create(:charge) }
    subject(:payment) { described_class.new }

    describe "#reference" do
      it "validates presence" do
        expect { payment.valid? }.to change { payment.errors[:reference] }.to ["Enter Reference"]
      end
    end

    describe "#payment_type" do
      it "validates presence" do
        expect { payment.valid? }.to change { payment.errors[:payment_type] }.to ["Enter Payment type"]
      end
    end

    describe "#amount" do
      it "validates presence" do
        expect { payment.valid? }.to change { payment.errors[:amount] }.to ["Enter Amount", "is not a number"]
      end
    end

    describe "#payment_date" do
      it "validates presence" do
        expect { payment.valid? }.to change { payment.errors[:payment_date] }.to ["Enter Payment date"]
      end
    end

    it "is invalid without a charge" do
      payment = build(:payment, charge: nil)
      expect(payment).not_to be_valid
      expect(payment.errors[:charge]).to include("must exist")
    end

    it "is invalid when amount is nil" do
      payment = build(:payment, amount: nil)
      expect(payment).not_to be_valid
      expect(payment.errors[:amount]).to include("Enter Amount")
    end

    it "is invalid when amount <= 0" do
      payment = build(:payment, amount: 0)
      expect(payment).not_to be_valid
      expect(payment.errors[:amount]).to include("must be greater than 0")
    end

    it "is valid when amount > 0" do
      payment = build(:payment, amount: 50)
      expect(payment).to be_valid
    end
  end

  describe "delegations" do
    it "delegates planning_application to charge" do
      charge = create(:charge)
      payment = create(:payment, charge: charge)
      expect(payment.planning_application).to eq(charge.planning_application)
    end
  end
end
