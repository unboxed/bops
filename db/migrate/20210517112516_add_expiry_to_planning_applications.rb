# frozen_string_literal: true

class AddExpiryToPlanningApplications < ActiveRecord::Migration[6.0]
  def change
    add_column :planning_applications, :expiry_date, :date
  end
end
