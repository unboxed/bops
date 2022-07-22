# frozen_string_literal: true

class AddReferenceToPlanningApplications < ActiveRecord::Migration[6.1]
  def up
    add_column :planning_applications, :reference, :string
    add_index :planning_applications, :reference

    PlanningApplication.all.find_each do |planning_application|
      planning_application.send(:set_reference)
      planning_application.save!
    end
  end

  def down
    remove_column :planning_applications, :reference
  end
end
