# frozen_string_literal: true

class CreatePolicySchedules < ActiveRecord::Migration[7.1]
  def change
    create_table :policy_schedules do |t|
      t.integer :number, null: false, index: {unique: true}
      t.string :name

      t.timestamps
    end
  end
end
