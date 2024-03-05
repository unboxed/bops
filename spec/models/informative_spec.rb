# frozen_string_literal: true

require "rails_helper"

RSpec.describe Informative do
  describe "validations" do
    subject(:informative) { described_class.new }

    it "has a valid factory" do
      informative = create(:informative)

      expect(informative).to be_valid
    end

    describe "#title" do
      it "validates presence" do
        expect do
          informative.valid?
        end.to change {
          informative.errors[:title]
        }.to ["Fill in the title of the informative"]
      end
    end

    describe "#text" do
      it "validates presence" do
        expect do
          informative.valid?
        end.to change {
          informative.errors[:text]
        }.to ["Fill in the text of the informative"]
      end
    end
  end
end
