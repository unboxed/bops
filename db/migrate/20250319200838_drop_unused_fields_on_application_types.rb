# frozen_string_literal: true

class DropUnusedFieldsOnApplicationTypes < ActiveRecord::Migration[7.2]
  class ApplicationType < ApplicationRecord
    self.table_name = "application_types"

    class Config < ApplicationRecord
      self.table_name = "application_type_configs"
    end

    belongs_to :config
  end

  def up
    safety_assured do
      remove_column :application_types, :part, :integer
      remove_column :application_types, :section, :string
      remove_column :application_types, :assessment_details, :string, array: true
      remove_column :application_types, :steps, :string, array: true, default: %w[validation consultation assessment review]
      remove_column :application_types, :consistency_checklist, :string, array: true
      remove_column :application_types, :document_tags, :jsonb, default: {}, null: false
      remove_column :application_types, :features, :jsonb, default: {}
      remove_column :application_types, :status, :string, default: "inactive", null: false
      remove_reference :application_types, :legislation, foreign_key: true
      remove_column :application_types, :configured, :boolean, default: false, null: false
      remove_column :application_types, :category, :string
      remove_column :application_types, :reporting_types, :string, array: true, default: [], null: false
      remove_column :application_types, :decisions, :string, array: true, default: [], null: false
    end
  end

  def down
    safety_assured do
      add_column :application_types, :part, :integer
      add_column :application_types, :section, :string
      add_column :application_types, :assessment_details, :string, array: true
      add_column :application_types, :steps, :string, array: true, default: %w[validation consultation assessment review]
      add_column :application_types, :consistency_checklist, :string, array: true
      add_column :application_types, :document_tags, :jsonb, default: {}, null: false
      add_column :application_types, :features, :jsonb, default: {}
      add_column :application_types, :status, :string, default: "inactive", null: false
      add_reference :application_types, :legislation, foreign_key: true
      add_column :application_types, :configured, :boolean, default: false, null: false
      add_column :application_types, :category, :string
      add_column :application_types, :reporting_types, :string, array: true, default: [], null: false
      add_column :application_types, :decisions, :string, array: true, default: [], null: false
    end

    ApplicationType.includes(:config).find_each do |application_type|
      next unless application_type.config

      application_type.update_columns(
        part: application_type.config.part,
        section: application_type.config.section,
        assessment_details: application_type.config.assessment_details,
        steps: application_type.config.steps,
        consistency_checklist: application_type.config.consistency_checklist,
        document_tags: application_type.config.document_tags,
        features: application_type.config.features,
        status: application_type.config.status,
        legislation_id: application_type.config.legislation_id,
        configured: application_type.config.configured,
        category: application_type.config.category,
        reporting_types: application_type.config.reporting_types,
        decisions: application_type.config.decisions
      )
    end
  end
end
