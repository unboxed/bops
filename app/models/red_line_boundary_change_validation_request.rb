# frozen_string_literal: true

class RedLineBoundaryChangeValidationRequest < ValidationRequest
  validates :reason, presence: true
  validates :new_geojson, presence: true
  validate :rejected_reason_is_present?
  validates :cancel_reason, presence: true, if: :cancelled?

  before_create :set_original_geojson

  format_geojson_epsg :original_geojson
  format_geojson_epsg :new_geojson

  before_create lambda {
    reset_validation_requests_update_counter!(planning_application.validation_requests.red_line_boundary_changes)
  }

  private

  def rejected_reason_is_present?
    return if planning_application.nil?
    return unless planning_application.invalidated?
    return unless applicant_approved == false && applicant_rejection_reason.blank?

    errors.add(:base,
      "Please include a comment for the case officer to " \
      "indicate why the red line boundary change has been rejected.")
  end

  def set_original_geojson
    self.original_geojson = planning_application.boundary_geojson
  end

  def audit_api_comment
    if applicant_approved?
      {applicant_response: "approved"}.to_json
    else
      {applicant_response: "rejected", reason: applicant_rejection_reason}.to_json
    end
  end

  def audit_comment
    reason
  end

  def update_planning_application_for_auto_closed_request!
    planning_application.update!(boundary_geojson: new_geojson)
  end
end
