# frozen_string_literal: true

class AddMissingPlanningApplicationForeignKeyOnConsultations < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :consultations, :planning_applications
  end
end
