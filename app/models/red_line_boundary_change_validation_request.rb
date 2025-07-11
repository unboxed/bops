# frozen_string_literal: true

class RedLineBoundaryChangeValidationRequest < ValidationRequest
  validates :reason, presence: true
  validates :new_geojson, presence: true
  validate :rejected_reason_is_present?
  validates :cancel_reason, presence: true, if: :cancelled?

  validate if: :applicant_responding? do
    if approved.nil?
      errors.add(:approved, :blank, message: "Tell us whether you agree or disagree with the proposed red line boundary")
    end

    if approved == false && rejection_reason.blank?
      errors.add(:rejection_reason, :blank, message: "Tell us why you disagree with the proposed red line boundary")
    end
  end

  before_create :set_original_geojson

  before_create lambda {
    reset_validation_requests_update_counter!(planning_application.red_line_boundary_change_validation_requests)
  }

  def update_planning_application!(*)
    planning_application.update!(boundary_geojson: new_geojson)
  end

  def new_geojson_before_type_cast
    new_geojson.to_json
  end

  def original_geojson_before_type_cast
    original_geojson.to_json
  end

  def new_geojson=(value)
    if value.is_a?(String)
      return if value.blank?
      super(JSON.parse(value))
    else
      super
    end
  end

  def original_geojson=(value)
    if value.is_a?(String)
      return if value.blank?
      super(JSON.parse(value))
    else
      super
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
    {reason: reason}.to_json
  end

  def update_planning_application_for_auto_closed_request!
    planning_application.update!(boundary_geojson: new_geojson)
  end
end
