# frozen_string_literal: true

class AddColumnsToAgents < ActiveRecord::Migration[6.0]
  def change
    add_column :agents, :first_name, :string
    add_column :agents, :last_name, :string
    add_column :agents, :company_name, :string
    add_column :agents, :company_number, :string
    add_column :agents, :address_1, :string
    add_column :agents, :address_2, :string
    add_column :agents, :address_3, :string
    add_column :agents, :town, :string
    add_column :agents, :postcode, :string
    add_column :agents, :country, :string
    add_column :agents, :phone_2, :string
  end
end
