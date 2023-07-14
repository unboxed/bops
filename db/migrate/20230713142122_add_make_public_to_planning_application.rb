# frozen_string_literal: true

class AddMakePublicToPlanningApplication < ActiveRecord::Migration[7.0]
  def change
    add_column :planning_applications, :make_public, :boolean, default: false
  end
end
