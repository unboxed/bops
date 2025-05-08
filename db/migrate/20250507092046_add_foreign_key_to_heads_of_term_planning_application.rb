# frozen_string_literal: true

class AddForeignKeyToHeadsOfTermPlanningApplication < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :heads_of_terms, :planning_applications, validate: false
  end
end
