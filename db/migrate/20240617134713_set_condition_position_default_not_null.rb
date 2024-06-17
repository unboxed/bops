# frozen_string_literal: true

class SetConditionPositionDefaultNotNull < ActiveRecord::Migration[7.1]
  def change
    up_only do
      Condition.where(position: nil).update_all(position: 0)
      change_column_default :conditions, :position, 0
    end

    add_check_constraint :conditions, "position IS NOT NULL", name: "conditions_position_null", validate: false
  end
end
