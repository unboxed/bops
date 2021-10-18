# frozen_string_literal: true

require "rails_helper"

RSpec.describe OtherChangeValidationRequest, type: :model do
  it_behaves_like "ValidationRequest", described_class, "other_change_validation_request"
end
