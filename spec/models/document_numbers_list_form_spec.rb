# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocumentNumbersListForm, type: :model do
  subject do
    described_class.new(documents_to_update, document_numbers_hash)
  end

  let(:documents_to_update) { create_list :document, 2 }

  describe "#update_all" do
    context "when the hash contains blank numbers" do
      let(:document_numbers_hash) do
        {
          documents_to_update.first.id.to_s => {
            "numbers" => "one, two",
          },
          documents_to_update.last.id.to_s => {
            "numbers" => "",
          },
        }
      end

      it "returns false" do
        expect(subject.update_all).to eq false
      end

      it "assigns errors to documents" do
        subject.update_all

        expect(subject.documents.last.errors).not_to be_empty
      end

      it "does not persist any document numbers to the database" do
        subject.update_all

        persisted_documents = Document.find(documents_to_update.map(&:id))

        persisted_documents.each do |document|
          expect(document.numbers).to be_empty
        end
      end
    end

    context "when the hash is missing an id for the supplied documents" do
      let(:document_numbers_hash) do
        {
          documents_to_update.first.id.to_s => {
            "numbers" => "one",
          },
          # no key for second document id
        }
      end

      it "returns false" do
        expect(subject.update_all).to eq false
      end
    end

    context "when the hash has keys for all documents with valid numbers" do
      let(:document_numbers_hash) do
        {
          documents_to_update.first.id.to_s => {
            "numbers" => "one, two",
          },
          documents_to_update.last.id.to_s => {
            "numbers" => "three",
          },
        }
      end

      it "returns true" do
        expect(subject.update_all).to eq true
      end

      it "assigns the numbers to the relevant documents" do
        subject.update_all

        expect(documents_to_update.first.numbers).to eq "one, two"
        expect(documents_to_update.last.numbers).to eq "three"
      end
    end
  end
end
