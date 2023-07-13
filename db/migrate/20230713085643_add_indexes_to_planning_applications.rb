# frozen_string_literal: true

class AddIndexesToPlanningApplications < ActiveRecord::Migration[7.0]
  def change
    add_index :planning_applications, %i[status application_type_id]
    add_index :planning_applications, [:status]
  end
end
