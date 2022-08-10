# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidationRequest, type: :model do
  describe "validations" do
    subject(:validation_request) { described_class.new }

    describe "#requestable_id" do
      it "validates presence" do
        expect { validation_request.valid? }.to change { validation_request.errors[:requestable_id] }.to ["can't be blank"]
      end
    end

    describe "#requestable_type" do
      it "validates presence and inclusion" do
        expect { validation_request.valid? }.to change { validation_request.errors[:requestable_type] }.to ["can't be blank", "is not included in the list"]
      end
    end

    describe "#planning_application" do
      it "validates presence and inclusion" do
        expect { validation_request.valid? }.to change { validation_request.errors[:planning_application] }.to ["must exist"]
      end
    end

    context "when there is existing record with identical requestable_id and requestable_type" do
      let(:validation_request) { create(:validation_request) }

      it "raises a non unique error if requestable_id and requestable_type are identical to an existing record" do
        expect do
          create(:validation_request, requestable_id: validation_request.id, requestable_type: validation_request.type)
        end.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end

  describe "constants" do
    describe "VALIDATION_REQUEST_TYPES" do
      it "returns the permitted validation request types" do
        expect(ValidationRequest::VALIDATION_REQUEST_TYPES).to eq(
          %w[
            AdditionalDocumentValidationRequest
            DescriptionChangeValidationRequest
            RedLineBoundaryChangeValidationRequest
            ReplacementDocumentValidationRequest
            OtherChangeValidationRequest
          ]
        )
      end
    end
  end
end
