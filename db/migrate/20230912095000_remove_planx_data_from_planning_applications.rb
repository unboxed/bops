# frozen_string_literal: true

class RemovePlanxDataFromPlanningApplications < ActiveRecord::Migration[7.0]
  def change
    remove_column :planning_applications, :planx_data, :jsonb
  end
end
