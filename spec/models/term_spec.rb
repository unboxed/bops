# frozen_string_literal: true

require "rails_helper"

RSpec.describe Term do
  include ActionDispatch::TestProcess::FixtureFile

  describe "validations" do
    subject(:term) { described_class.new }

    describe "#text" do
      it "validates presence" do
        expect do
          term.valid?
        end.to change {
          term.errors[:text]
        }.to ["Enter the detail of this term"]
      end
    end

    describe "#title" do
      it "validates presence" do
        expect do
          term.valid?
        end.to change {
          term.errors[:title]
        }.to ["Enter the title of this term"]
      end
    end
  end
end
