# frozen_string_literal: true

class CreatePreapplicationServices < ActiveRecord::Migration[7.2]
  def change
    create_table :preapplication_services do |t|
      t.string :name
      t.references :planning_application, null: false, foreign_key: true

      t.timestamps
    end
  end
end
