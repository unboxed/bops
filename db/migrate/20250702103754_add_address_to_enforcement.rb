# frozen_string_literal: true

class AddAddressToEnforcement < ActiveRecord::Migration[7.2]
  def change
    add_column :enforcements, :address_line_1, :string
    add_column :enforcements, :address_line_2, :string
    add_column :enforcements, :town, :string
    add_column :enforcements, :county, :string
    add_column :enforcements, :postcode, :string
  end
end
