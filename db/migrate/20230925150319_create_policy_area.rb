# frozen_string_literal: true

class CreatePolicyArea < ActiveRecord::Migration[7.0]
  def change
    create_table :policy_areas do |t|
      t.references :planning_application, null: false
      t.timestamps
    end

    create_table :considerations do |t|
      t.string :area
      t.string :policies
      t.string :guidance
      t.text :assessment
      t.references :policy_area, null: false
      t.timestamps
    end
  end
end
