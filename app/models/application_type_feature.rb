# frozen_string_literal: true

class ApplicationTypeFeature
  include StoreModel::Model

  attribute :appeals, :boolean, default: true
  attribute :assess_against_policies, :boolean, default: false
  attribute :cil, :boolean, default: true
  attribute :considerations, :boolean, default: false
  attribute :consultation_steps, :list, default: -> { [] }
  attribute :consultations_skip_bank_holidays, :boolean, default: false
  attribute :description_change_requires_validation, :boolean, default: true
  attribute :eia, :boolean, default: true
  attribute :heads_of_terms, :boolean, default: true
  attribute :immunity, :boolean, default: true
  attribute :informatives, :boolean, default: false
  attribute :legislative_requirements, :boolean, default: true
  attribute :ownership_details, :boolean, default: true
  attribute :permitted_development_rights, :boolean, default: true
  attribute :planning_conditions, :boolean, default: false
  attribute :publishable, :boolean, default: true
  attribute :site_visits, :boolean, default: true

  validate :consultation_steps_are_valid

  private

  def consultation_steps_are_valid
    invalid_steps = consultation_steps.reject { |step| Consultation::STEPS.include?(step) }

    unless invalid_steps.empty?
      errors.add(:consultation_steps, "contains invalid steps: #{invalid_steps.join(", ")}")
    end
  end
end
