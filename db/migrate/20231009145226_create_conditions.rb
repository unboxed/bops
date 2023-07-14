# frozen_string_literal: true

class CreateConditions < ActiveRecord::Migration[7.0]
  def change
    create_table :conditions do |t|
      t.string :title
      t.text :text
      t.text :reason
      t.boolean :standard
      t.references :planning_application, null: false
      t.timestamps
    end
  end
end
