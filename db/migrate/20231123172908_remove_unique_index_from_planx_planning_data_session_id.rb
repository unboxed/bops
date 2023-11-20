# frozen_string_literal: true

class RemoveUniqueIndexFromPlanxPlanningDataSessionId < ActiveRecord::Migration[7.0]
  def change
    remove_index :planx_planning_data, :session_id
  end
end
