# frozen_string_literal: true

class OtherChangeValidationRequest < ApplicationRecord
  include ValidationRequest

  belongs_to :planning_application
  belongs_to :user

  validates :summary, presence: true
  validates :suggestion, presence: true

  validate :response_is_present?

  def response_is_present?
    errors.add(:base, "some suggestion error here") if closed? && response.blank?
  end
end
