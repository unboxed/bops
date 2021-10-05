# frozen_string_literal: true

class RemoveWardFromPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    remove_column :planning_applications, :ward
  end
end
