# frozen_string_literal: true

class AddLegislationCheckedToPlanningApplications < ActiveRecord::Migration[7.0]
  def change
    add_column :planning_applications, :legislation_checked, :boolean, null: false, default: false
  end
end
