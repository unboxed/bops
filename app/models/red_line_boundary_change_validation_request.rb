# frozen_string_literal: true

class RedLineBoundaryChangeValidationRequest < ApplicationRecord
  include ValidationRequest

  belongs_to :planning_application
  belongs_to :user

  validates :new_geojson, presence: { message: "Red line drawing must be complete" }
  validates :reason, presence: { message: "Provide a reason for changes" }

  validate :rejected_reason_is_present?

  before_create :set_original_geojson

  def rejected_reason_is_present?
    if approved == false && rejection_reason.blank?
      errors.add(:base,
                 "Please include a comment for the case officer to indicate why the red line boundary change has been rejected.")
    end
  end

  def geojson
    new_geojson.presence || planning_application.boundary_geojson
  end

  private

  def set_original_geojson
    self.original_geojson = planning_application.boundary_geojson
  end

  def audit_api_comment
    if approved?
      { response: "approved" }.to_json
    else
      { response: "rejected", reason: rejection_reason }.to_json
    end
  end

  def audit_comment
    reason
  end
end
