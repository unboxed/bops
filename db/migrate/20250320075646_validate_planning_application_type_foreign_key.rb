# frozen_string_literal: true

class ValidatePlanningApplicationTypeForeignKey < ActiveRecord::Migration[7.2]
  def change
    validate_foreign_key :planning_applications, :application_types
  end
end
