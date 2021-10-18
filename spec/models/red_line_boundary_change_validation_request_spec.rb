# frozen_string_literal: true

require "rails_helper"

RSpec.describe RedLineBoundaryChangeValidationRequest, type: :model do
  it_behaves_like "ValidationRequest", described_class, "red_line_boundary_change_validation_request"
end
