# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdditionalDocumentValidationRequest, type: :model do
  it_behaves_like "ValidationRequest", described_class, "additional_document_validation_request"
end
