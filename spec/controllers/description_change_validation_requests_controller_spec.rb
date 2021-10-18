# frozen_string_literal: true

require "rails_helper"

RSpec.describe DescriptionChangeValidationRequestsController, type: :controller do
  it_behaves_like "ValidationRequests", described_class,
                  "description_change_validation_request"
end
