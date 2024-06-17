# frozen_string_literal: true

class ValidateSetConditionPositionDefaultNotNull < ActiveRecord::Migration[7.1]
  def up
    validate_check_constraint :conditions, name: "conditions_position_null"
    change_column_null :conditions, :position, false
    remove_check_constraint :conditions, name: "conditions_position_null"
  end

  def down
    add_check_constraint :conditions, "position IS NOT NULL", name: "conditions_position_null", validate: false
    change_column_null :conditions, :position, true
  end
end
