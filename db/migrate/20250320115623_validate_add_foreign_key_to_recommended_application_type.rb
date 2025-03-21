# frozen_string_literal: true

class ValidateAddForeignKeyToRecommendedApplicationType < ActiveRecord::Migration[7.2]
  def change
    validate_foreign_key :planning_applications, :application_types, column: :recommended_application_type_id
  end
end
