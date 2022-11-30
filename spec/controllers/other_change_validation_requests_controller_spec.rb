# frozen_string_literal: true

require "rails_helper"

RSpec.describe OtherChangeValidationRequestsController do
  it_behaves_like "ValidationRequests", described_class, "other_change_validation_request"
end
