# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReplacementDocumentValidationRequestsController, type: :controller do
  it_behaves_like "ValidationRequests", described_class,
                  "replacement_document_validation_request"
end
