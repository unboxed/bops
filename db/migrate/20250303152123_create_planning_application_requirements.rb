# frozen_string_literal: true

class CreatePlanningApplicationRequirements < ActiveRecord::Migration[7.2]
  def change
    create_table :planning_application_requirements do |t|
      t.references :planning_application, null: false, index: true, foreign_key: true
      t.string :description, null: false
      t.string :url
      t.text :guidelines
      t.text :additional_comments
      t.string :source, default: "BOPS"
      t.string :category, limit: 30
      t.timestamps
    end
  end
end
