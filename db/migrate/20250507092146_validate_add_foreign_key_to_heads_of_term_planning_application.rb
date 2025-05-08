# frozen_string_literal: true

class ValidateAddForeignKeyToHeadsOfTermPlanningApplication < ActiveRecord::Migration[7.2]
  def change
    validate_foreign_key :heads_of_terms, :planning_applications
  end
end
