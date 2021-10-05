# frozen_string_literal: true

class AddUserToPlanningApplications < ActiveRecord::Migration[6.0]
  def change
    add_reference :planning_applications, :user, null: false, foreign_key: true
  end
end
