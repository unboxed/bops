# frozen_string_literal: true

class RedLineBoundaryChangeValidationRequest < ValidationRequest
  validates :reason, presence: true
  validates :new_geojson, presence: true
  validate :rejected_reason_is_present?

  before_create :set_original_geojson

  format_geojson_epsg :original_geojson
  format_geojson_epsg :new_geojson

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
end
