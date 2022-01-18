# frozen_string_literal: true

class AddPlanXDataToPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :planning_applications, :planx_data, :jsonb
  end
end
