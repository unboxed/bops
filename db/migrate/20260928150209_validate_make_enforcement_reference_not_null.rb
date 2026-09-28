# frozen_string_literal: true

class ValidateMakeEnforcementReferenceNotNull < ActiveRecord::Migration[8.1]
  def up
    validate_check_constraint :enforcements, name: "enforcements_reference_null"
    change_column_null :enforcements, :reference, false
    remove_check_constraint :enforcements, name: "enforcements_reference_null"
  end

  def down
    add_check_constraint :enforcements, "reference IS NOT NULL", name: "enforcements_reference_null", validate: false
    change_column_null :enforcements, :reference, true
  end
end
