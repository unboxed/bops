# frozen_string_literal: true

class EnvironmentImpactAssessment < ApplicationRecord
  include Auditable

  belongs_to :planning_application

  validates :fee, presence: {unless: -> { address.blank? }}
  validates :address, presence: {unless: -> { fee.blank? }}

  after_commit :modify_expiry_date
  before_save :create_audit!

  with_options to: :planning_application do
    delegate :audits
  end

  private

  def create_audit!
    return unless valid?

    comment = required_changed? ? "Changed from: #{!required} Changed to: #{required}" : "Changed to: #{required}"
    audit!(
      activity_type: "updated",
      activity_information: "Environment impact assessment",
      audit_comment: comment
    )
  end

  def modify_expiry_date
    planning_application.modify_expiry_date
  end
end
