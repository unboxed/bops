# frozen_string_literal: true

class CreateEnforcement < ActiveRecord::Migration[7.2]
  def change
    create_table :enforcements do |t|
      t.string :breach_description
      t.string :status
      t.boolean :urgent, default: false, null: false

      t.timestamps
    end
  end
end
