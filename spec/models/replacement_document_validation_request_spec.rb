# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReplacementDocumentValidationRequest, type: :model do
  it_behaves_like "ValidationRequest", described_class, "replacement_document_validation_request"

  describe "validations" do
    subject(:replacement_document_validation_request) { described_class.new }

    describe "#reason" do
      it "validates presence" do
        expect do
          replacement_document_validation_request.valid?
        end.to change {
          replacement_document_validation_request.errors[:reason]
        }.to ["can't be blank"]
      end
    end

    describe "#user" do
      it "validates presence" do
        expect do
          replacement_document_validation_request.valid?
        end.to change {
          replacement_document_validation_request.errors[:user]
        }.to ["must exist"]
      end
    end

    describe "#planning_application" do
      it "validates presence" do
        expect do
          replacement_document_validation_request.valid?
        end.to change {
          replacement_document_validation_request.errors[:planning_application]
        }.to ["must exist"]
      end
    end

    describe "#old_document" do
      it "validates presence" do
        expect do
          replacement_document_validation_request.valid?
        end.to change {
          replacement_document_validation_request.errors[:old_document]
        }.to ["must exist"]
      end
    end
  end
end
