# frozen_string_literal: true

class DescriptionChangeValidationRequest < ValidationRequest
  validates :proposed_description, presence: true
  validate :allows_only_one_open_description_change, on: :create
  validate :planning_application_has_not_been_determined, on: :create
  validate :rejected_reason_is_present?

  before_create :set_previous_application_description

  private

  def allows_only_one_open_description_change
    return if planning_application.nil?
    return unless planning_application.validation_requests.description_changes.open.any?

    errors.add(:base, "An open description change already exists for this planning application.")
  end

  def planning_application_has_not_been_determined
    return if planning_application.nil?
    return unless planning_application.determined?

    errors.add(:base, "A description change request cannot be submitted for a determined planning application.")
  end

  def rejected_reason_is_present?
    return if planning_application.nil?
    return unless planning_application.invalidated?
    return unless applicant_approved == false && applicant_rejection_reason.blank?

    errors.add(:base,
      "Please include a comment for the case officer to " \
      "indicate why the red line boundary change has been rejected.")
  end

  def set_previous_application_description
    self.previous_description = planning_application.description
  end
end
