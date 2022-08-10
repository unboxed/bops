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
  belongs_to :planning_application

  validates :requestable_id, presence: true
  validates :requestable_type, presence: true, inclusion: { in: VALIDATION_REQUEST_TYPES }

  scope :closed, -> { where.not(closed_at: nil) }

  VALIDATION_REQUEST_TYPES.each do |type|
    scope "#{type.underscore}s", -> { where(requestable_type: type) }
  end
end
