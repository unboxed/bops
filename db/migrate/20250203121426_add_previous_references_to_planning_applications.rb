# frozen_string_literal: true

class AddPreviousReferencesToPlanningApplications < ActiveRecord::Migration[7.2]
  def change
    add_column :planning_applications, :previous_references, :string, array: true, default: []
  end
end
