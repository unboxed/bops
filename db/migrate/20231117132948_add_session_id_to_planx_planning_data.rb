# frozen_string_literal: true

class AddSessionIdToPlanxPlanningData < ActiveRecord::Migration[7.0]
  def change
    add_column :planx_planning_data, :session_id, :string, null: true
    add_index :planx_planning_data, :session_id, unique: true
  end
end
