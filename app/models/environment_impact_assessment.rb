# frozen_string_literal: true

class EnvironmentImpactAssessment < ApplicationRecord
  include Auditable

  belongs_to :planning_application

  validates :fee, presence: {unless: -> { address.blank? }}
  validates :address, presence: {unless: -> { fee.blank? }}

  with_options format: {with: URI::MailTo::EMAIL_REGEXP} do
    validates :email_address, allow_blank: true
  end

  before_save :create_audit!
  after_create :modify_expiry_date
  after_update :modify_expiry_date, unless: :required?

  with_options to: :planning_application do
    delegate :audits
    delegate :modify_expiry_date
  end

  def with_address_email_and_fee?
    address && email_address && fee
  end

  def with_address_and_fee?
    address && fee
  end

  def with_email_and_fee?
    email_address && fee
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
end
