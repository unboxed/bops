# frozen_string_literal: true

class RenameEnforcementAddressLinesAndDescription < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      rename_column :enforcements, :address_line_1, :address_1
      rename_column :enforcements, :address_line_2, :address_2
      rename_column :enforcements, :breach_description, :description
    end
  end
end
