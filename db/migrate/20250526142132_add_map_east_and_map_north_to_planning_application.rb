# frozen_string_literal: true

class AddMapEastAndMapNorthToPlanningApplication < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      change_table :planning_applications, bulk: true do |t|
        t.string :map_east
        t.string :map_north
      end
    end
  end
end
