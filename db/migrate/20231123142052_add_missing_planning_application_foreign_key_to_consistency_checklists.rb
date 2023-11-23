# frozen_string_literal: true

class AddMissingPlanningApplicationForeignKeyToConsistencyChecklists < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :consistency_checklists, :planning_applications
  end
end
