# frozen_string_literal: true

class RemoveNotNullConstraintOnPlanxPlanningDataEntry < ActiveRecord::Migration[7.0]
  def change
    change_column_null(:planx_planning_data, :entry, true)
  end
end
