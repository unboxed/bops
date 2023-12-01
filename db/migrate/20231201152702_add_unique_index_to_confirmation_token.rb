# frozen_string_literal: true

class AddUniqueIndexToConfirmationToken < ActiveRecord::Migration[7.0]
  def change
    add_index :users, :confirmation_token, unique: true
  end
end
