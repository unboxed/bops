# frozen_string_literal: true

class AddMobileNumberToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :mobile_number, :string, unique: true
  end
end
