# frozen_string_literal: true

class AddChangeAccessIdToPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :planning_applications, :change_access_id, :string
  end
end
