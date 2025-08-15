# frozen_string_literal: true

class AddComplainantDetailsToEnforcements < ActiveRecord::Migration[7.2]
  def change
    add_column :enforcements, :complainant_name, :string
    add_column :enforcements, :complainant_email_address, :string
    add_column :enforcements, :complainant_phone_number, :string
    add_column :enforcements, :complainant_address, :string
  end
end
