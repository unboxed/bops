# frozen_string_literal: true

class CreateEnforcementInterestedParties < ActiveRecord::Migration[8.1]
  def change
    create_table :enforcement_interested_parties do |t|
      t.references :enforcement, foreign_key: true
      t.string :name, null: false
      t.string :company_name
      t.string :address_1
      t.string :address_2
      t.string :town
      t.string :county
      t.string :postcode
      t.string :email_address
      t.string :phone
      t.string :relationship, null: false
      t.string :other_relationship
      t.timestamps
    end
  end
end
