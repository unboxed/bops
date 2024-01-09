# frozen_string_literal: true

class RedLineBoundaryChangeValidationRequest < ValidationRequest
  validates :reason, presence: true
  validates :new_geojson, presence: true
  validate :rejected_reason_is_present?
  validates :cancel_reason, presence: true, if: :cancelled?

  before_create :set_original_geojson

  before_create lambda {
    reset_validation_requests_update_counter!(planning_application.red_line_boundary_change_validation_requests)
  }

  def update_planning_application!(params)
    planning_application.update!(boundary_geojson: new_geojson)
  end

  def new_geojson=(value)
    if value.is_a?(String)
      return if value.blank?
      super(JSON.parse(value))
    else
      super(value)
    end
  end

  def original_geojson=(value)
    if value.is_a?(String)
      return if value.blank?
      super(JSON.parse(value))
    else
      super(value)
    end
  end

  private

  def rejected_reason_is_present?
    return if planning_application.nil?
    return unless planning_application.invalidated?
    return unless approved == false && rejection_reason.blank?

    errors.add(:base,
      "Please include a comment for the case officer to " \
      "indicate why the red line boundary change has been rejected.")
  end

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

  def update_planning_application_for_auto_closed_request!
    planning_application.update!(boundary_geojson: new_geojson)
  end
end
