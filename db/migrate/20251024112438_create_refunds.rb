# frozen_string_literal: true

class CreateRefunds < ActiveRecord::Migration[8.0]
  def change
    create_table :refunds do |t|
      t.decimal :amount
      t.date :date
      t.string :payment_type
      t.string :reference
      t.string :reason
      t.references :planning_application, null: false, foreign_key: true

      t.timestamps
    end
  end
end
