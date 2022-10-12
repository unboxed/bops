# frozen_string_literal: true

class CreatePermittedDevelopmentRights < ActiveRecord::Migration[6.1]
  def change
    create_table :permitted_development_rights do |t|
      t.string :status, null: false
      t.boolean :removed
      t.text :removed_reason
      t.references :planning_application

      t.timestamps
    end
  end
end
