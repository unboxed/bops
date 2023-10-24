# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdditionalDocumentValidationRequestsController do
  it_behaves_like "ValidationRequests", described_class,
    "additional_document_validation_request"
end
