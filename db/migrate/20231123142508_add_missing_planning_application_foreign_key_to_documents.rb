# frozen_string_literal: true

class AddMissingPlanningApplicationForeignKeyToDocuments < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :documents, :planning_applications
  end
end
