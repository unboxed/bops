# frozen_string_literal: true

class CreateFeeCalculations < ActiveRecord::Migration[7.0]
  def change
    create_table :fee_calculations do |t|
      t.references :planning_application, null: false, foreign_key: true

      t.decimal :total_fee, precision: 10, scale: 2
      t.decimal :payable_fee, precision: 10, scale: 2
      t.decimal :requested_fee, precision: 10, scale: 2
      t.string :exemptions, array: true, default: []
      t.string :reductions, array: true, default: []

      t.timestamps
    end
  end
end
