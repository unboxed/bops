# frozen_string_literal: true

require "rails_helper"

RSpec.describe DrawingNumbersListForm, type: :model do
  let(:drawings_to_update) { create_list :drawing, 2 }

  subject do
    described_class.new(drawings_to_update, drawing_numbers_hash)
  end

  describe "#update_all" do
    context "when the hash contains blank numbers" do
      let(:drawing_numbers_hash) do
        {
          drawings_to_update.first.id.to_s => {
            "numbers" => "one, two"
          },
          drawings_to_update.last.id.to_s => {
            "numbers" => ""
          }
        }
      end

      it "returns false" do
        expect(subject.update_all).to eq false
      end

      it "assigns errors to drawings" do
         subject.update_all

         expect(subject.drawings.last.errors).not_to be_empty
      end

      it "does not persist any drawing numbers to the database" do
         subject.update_all

         persisted_drawings = Drawing.find(drawings_to_update.map(&:id))

         persisted_drawings.each do |drawing|
          expect(drawing.numbers).to be_empty
         end
      end
    end

    context "when the hash is missing an id for the supplied drawings" do
      let(:drawing_numbers_hash) do
        {
          drawings_to_update.first.id.to_s => {
            "numbers" => "one"
          },
          # no key for second drawing id
        }
      end

      it "returns false" do
        expect(subject.update_all).to eq false
      end
    end

    context "when the hash has keys for all drawings with valid numbers" do
      let(:drawing_numbers_hash) do
        {
          drawings_to_update.first.id.to_s => {
            "numbers" => "one, two"
          },
          drawings_to_update.last.id.to_s => {
            "numbers" => "three"
          }
        }
      end

      it "returns true" do
        expect(subject.update_all).to eq true
      end

      it "assigns the numbers to the relevant drawings" do
        subject.update_all

        expect(drawings_to_update.first.numbers).to eq "one, two"
        expect(drawings_to_update.last.numbers).to eq "three"
      end
    end
  end
end
