# frozen_string_literal: true

class AddMissingPlanningApplicationForeignKeyToPolicyClasses < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :policy_classes, :planning_applications
  end
end
