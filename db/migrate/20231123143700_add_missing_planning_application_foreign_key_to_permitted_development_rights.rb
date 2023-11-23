# frozen_string_literal: true

class AddMissingPlanningApplicationForeignKeyToPermittedDevelopmentRights < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :permitted_development_rights, :planning_applications
  end
end
