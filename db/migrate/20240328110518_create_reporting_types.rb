# frozen_string_literal: true

class CreateReportingTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :reporting_types do |t|
      t.string :code, null: false
      t.string :category, null: false
      t.string :description, null: false
      t.string :guidance
      t.string :guidance_link
      t.string :legislation

      t.timestamps
    end

    add_index :reporting_types, :code, unique: true
  end
end
