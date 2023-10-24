# frozen_string_literal: true

class RedLineBoundaryChangeValidationRequest < ApplicationRecord
  class ResetRedLineBoundaryInvalidationError < StandardError; end

  include ValidationRequestable

  include GeojsonFormattable

  belongs_to :planning_application
  belongs_to :user

  validates :new_geojson, presence: true
  validates :reason, presence: true

  validate :rejected_reason_is_present?

  before_create :set_original_geojson
  before_create lambda {
    reset_validation_requests_update_counter!(planning_application.red_line_boundary_change_validation_requests)
  }

  delegate :reset_validation_requests_update_counter!, to: :planning_application

  format_geojson_epsg :original_geojson
  format_geojson_epsg :new_geojson

  def rejected_reason_is_present?
    return unless approved == false && rejection_reason.blank?

    errors.add(:base,
      "Please include a comment for the case officer to " \
      "indicate why the red line boundary change has been rejected.")
  end

  def geojson
    new_geojson.presence || planning_application.boundary_geojson
  end

  def update_planning_application_for_auto_closed_request!
    planning_application.update!(boundary_geojson: new_geojson)
  end

  def reset_red_line_boundary_invalidation
    transaction do
      planning_application.red_line_boundary_change_validation_requests.closed.max_by(&:closed_at)&.update_counter!
      planning_application.update!(valid_red_line_boundary: nil)
    end
  rescue ActiveRecord::ActiveRecordError => e
    raise ResetRedLineBoundaryInvalidationError, e.message
  end

  private

  def set_original_geojson
    self.original_geojson = planning_application.boundary_geojson
  end

  def audit_api_comment
    if approved?
      {response: "approved"}.to_json
    else
      {response: "rejected", reason: rejection_reason}.to_json
    end
  end

  def audit_comment
    reason
  end
end
