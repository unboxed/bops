# frozen_string_literal: true

class ApplicationTypeFeature
  include StoreModel::Model

  attribute :assess_against_policies, :boolean, default: false
  attribute :considerations, :boolean, default: false
  attribute :informatives, :boolean, default: false
  attribute :ownership_details, :boolean, default: true
  attribute :planning_conditions, :boolean, default: false
  attribute :permitted_development_rights, :boolean, default: true
  attribute :site_visits, :boolean, default: false
  attribute :consultations_skip_bank_holidays, :boolean, default: false
  attribute :consultation_steps, :list, default: -> { [] }

  validate :consultation_steps_are_valid

  private

  def consultation_steps_are_valid
    invalid_steps = consultation_steps.reject { |step| Consultation::STEPS.include?(step) }

    unless invalid_steps.empty?
      errors.add(:consultation_steps, "contains invalid steps: #{invalid_steps.join(", ")}")
    end
  end
end
