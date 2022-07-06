# frozen_string_literal: true

class AddParishNameToPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :planning_applications, :parish_name, :string
  end
end
