# frozen_string_literal: true

class AddForeignKeyBackToPlanningApplicationType < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :planning_applications, :application_types, validate: false
  end
end
