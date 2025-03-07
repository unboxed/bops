# frozen_string_literal: true

FactoryBot.define do
  factory :application_type do
    local_authority
    association :config, factory: :application_type_config
    code { config.code }
    name { config.name }
    suffix { config.suffix }

    %i[
      lawfulness_certificate
      ldc_existing
      ldc_proposed
      listed
      prior_approval
      pa_part1_classA
      pa_part_14_class_j
      pa_part_20_class_ab
      pa_part_3_class_ma
      pa_part7_classM
      planning_permission
      householder
      householder_retrospective
      minor
      major
      listed
      land_drainage
      pre_application
      without_consultation
      configured
      without_legislation
      without_category
      without_reporting_types
      active
      inactive
    ].each do |name|
      trait name do
        association :config, name, factory: :application_type_config
      end
    end

    initialize_with { local_authority.application_types.find_or_create_by(code:) }
  end
end
