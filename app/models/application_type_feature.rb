# frozen_string_literal: true

class ApplicationTypeFeature
  include StoreModel::Model

  attribute :appeals, :boolean, default: true
  attribute :assess_against_policies, :boolean, default: false
  attribute :cil, :boolean, default: true
  attribute :considerations, :boolean, default: false
  attribute :eia, :boolean, default: true
  attribute :informatives, :boolean, default: false
  attribute :legislative_requirements, :boolean, default: true
  attribute :ownership_details, :boolean, default: true
  attribute :planning_conditions, :boolean, default: false
  attribute :permitted_development_rights, :boolean, default: true
  attribute :site_visits, :boolean, default: true
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
