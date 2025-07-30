# frozen_string_literal: true

class ApplicationTypeFeature
  include StoreModel::Model

  APPLICATION_DETAILS_FEATURES = {
    assess_against_policies: false,
    cil: true,
    considerations: false,
    description_change_requires_validation: true,
    eia: true,
    heads_of_terms: true,
    immunity: true,
    informatives: false,
    legislative_requirements: true,
    ownership_details: true,
    permitted_development_rights: true,
    planning_conditions: false,
    publishable: true,
    site_visits: true
  }.freeze
  CONSULTATION_FEATURES = {consultations_skip_bank_holidays: false}.freeze
  OTHER_FEATURES = {appeals: true}.freeze
  ALL_FEATURES = APPLICATION_DETAILS_FEATURES.merge(CONSULTATION_FEATURES).merge(OTHER_FEATURES)

  attribute :consultation_steps, :list, default: -> { [] }

  ALL_FEATURES.each do |feature, default|
    attribute feature, :boolean, default: default
  end

  validate :consultation_steps_are_valid

  private

  def consultation_steps_are_valid
    invalid_steps = consultation_steps.reject { |step| Consultation::STEPS.include?(step) }

    unless invalid_steps.empty?
      errors.add(:consultation_steps, "contains invalid steps: #{invalid_steps.join(", ")}")
    end
  end
end
