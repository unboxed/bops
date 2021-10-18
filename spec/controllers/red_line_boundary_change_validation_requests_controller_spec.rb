# frozen_string_literal: true

require "rails_helper"

RSpec.describe RedLineBoundaryChangeValidationRequestsController, type: :controller do
  it_behaves_like "ValidationRequests", described_class,
                  "red_line_boundary_change_validation_request"
end
