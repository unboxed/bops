# frozen_string_literal: true

class AddLatitudeAndLongitudeToPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    change_table :planning_applications, bulk: true do |t|
      t.string :latitude
      t.string :longitude
    end
  end
end
