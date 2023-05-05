# frozen_string_literal: true

require "rails_helper"

RSpec.describe MobileNumberForm do
  it_behaves_like("PhoneNumberValidator") do
    let(:record) { described_class.new }
    let(:attribute) { :mobile_number }
  end

  describe "#valid?" do
    context "when mobile number is blank" do
      let(:form) { described_class.new(mobile_number: nil) }

      it "returns true" do
        expect(form.valid?).to be(false)
      end

      it "sets error" do
        form.valid?

        expect(
          form.errors.messages[:mobile_number]
        ).to contain_exactly(
          "can't be blank"
        )
      end
    end
  end
end
