# frozen_string_literal: true

class AddYearToPlanningApplication < ActiveRecord::Migration[8.1]
  def change
    add_column :planning_applications, :year, :integer

    up_only do
      safety_assured { execute("UPDATE planning_applications SET year = date_part('year', created_at) WHERE year IS NULL") }
    end

    safety_assured do
      change_column_null :planning_applications, :year, false
    end
  end
end
