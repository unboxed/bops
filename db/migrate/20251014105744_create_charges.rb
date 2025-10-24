# frozen_string_literal: true

class CreateCharges < ActiveRecord::Migration[8.0]
  def change
    create_table :charges do |t|
      t.string :description
      t.decimal :amount
      t.date :payment_due_date
      t.references :planning_application, null: false, foreign_key: true

      t.timestamps
    end
  end
end
