# frozen_string_literal: true

class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.decimal :amount
      t.date :payment_date
      t.string :payment_type
      t.string :reference
      t.references :charge, null: true, foreign_key: true

      t.timestamps
    end
  end
end
