# frozen_string_literal: true

class OtherChangeValidationRequest < ApplicationRecord
  include ValidationRequest
  belongs_to :planning_application
  belongs_to :user

  before_create :set_sequence

  validates :summary, presence: true
  validates :suggestion, presence: true

  validate :response_is_present?

  scope :open, -> { where(state: "open") }

  def response_is_present?
    if state == "closed" && response.blank?
      errors.add(:base, "some suggestion error here")
    end
  end
end
