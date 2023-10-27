# frozen_string_literal: true

class CreateConditionSets < ActiveRecord::Migration[7.0]
  def change
    create_table :condition_sets do |t|
      t.references :planning_application, null: false, foreign_key: true, index: true
      t.timestamps
    end

    add_reference :conditions, :condition_set, foreign_key: true, index: true
  end
end
