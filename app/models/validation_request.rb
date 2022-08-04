# frozen_string_literal: true

class ValidationRequest < ApplicationRecord
  VALIDATION_REQUEST_TYPES = %w[
    AdditionalDocumentValidationRequest
    DescriptionChangeValidationRequest
    RedLineBoundaryChangeValidationRequest
    ReplacementDocumentValidationRequest
    OtherChangeValidationRequest
  ].freeze

  belongs_to :requestable, polymorphic: true

  validates :requestable_id, presence: true
  validates :requestable_type, presence: true, inclusion: { in: VALIDATION_REQUEST_TYPES }

  delegate :planning_application, to: :requestable
end
