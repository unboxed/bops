# frozen_string_literal: true

require "rails_helper"

RSpec.describe Charge, type: :model do
  let(:charge) { create(:charge) }

  describe "validations" do
    subject(:charge) { described_class.new }

    describe "#description" do
      it "validates presence" do
        expect { charge.valid? }.to change { charge.errors[:description] }.to ["Enter Description"]
      end
    end

    describe "#amount" do
      it "validates presence" do
        expect { charge.valid? }.to change { charge.errors[:amount] }.to ["Enter Amount"]
      end
    end

    describe "nested attributes" do
      it "accepts nested payment attributes" do
        application = create(:planning_application)

        charge = application.charges.create!(
          amount: 100.00,
          description: "Application fee",
          payment_attributes: {
            amount: 50.00,
            payment_type: "BACS",
            reference: "REF111",
            payment_date: "01/10/2025"
          }
        )

        expect(charge.payment).to be_present
        expect(charge.payment.amount).to eq(50.00)
      end
    end
  end
end
