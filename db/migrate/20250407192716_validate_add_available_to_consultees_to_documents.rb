# frozen_string_literal: true

class ValidateAddAvailableToConsulteesToDocuments < ActiveRecord::Migration[7.2]
  def up
    validate_check_constraint :documents, expression: "available_to_consultees IS NOT NULL"
    change_column_null :documents, :available_to_consultees, false
    remove_check_constraint :documents, expression: "available_to_consultees IS NOT NULL"
  end

  def down
    add_check_constraint :documents, "available_to_consultees IS NOT NULL", validate: false
    change_column_null :documents, :available_to_consultees, true
  end
end
