# frozen_string_literal: true

class CreateAdditionalServices < ActiveRecord::Migration[7.2]
  def change
    create_table :additional_services do |t|
      t.string :type
      t.string :name
      t.references :planning_application, null: false, foreign_key: true

      t.timestamps
    end
  end
end
