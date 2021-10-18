# frozen_string_literal: true

require "rails_helper"

RSpec.describe DescriptionChangeValidationRequest, type: :model do
  it_behaves_like "ValidationRequest", described_class, "description_change_validation_request"
end
