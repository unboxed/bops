# frozen_string_literal: true

class AddMapEastAndMapNorthToPlanningApplication < ActiveRecord::Migration[7.2]
  def change
    add_column :planning_applications, :map_east, :string
    add_column :planning_applications, :map_north, :string
  end
end
