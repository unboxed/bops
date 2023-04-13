# frozen_string_literal: true

class AddWardInformationToPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :planning_applications, :ward, :string
    add_column :planning_applications, :ward_type, :string
  end
end
