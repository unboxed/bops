# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReplacementDocumentValidationRequest, type: :model do
  it_behaves_like "ValidationRequest", described_class, "replacement_document_validation_request"
end
