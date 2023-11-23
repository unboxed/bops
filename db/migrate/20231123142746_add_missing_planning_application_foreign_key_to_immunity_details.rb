# frozen_string_literal: true

class AddMissingPlanningApplicationForeignKeyToImmunityDetails < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :immunity_details, :planning_applications
  end
end
