# frozen_string_literal: true

class AddForeignKeyToRecommendedApplicationType < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :planning_applications, :application_types, column: :recommended_application_type_id, validate: false
  end
end
