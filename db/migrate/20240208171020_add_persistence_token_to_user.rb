# frozen_string_literal: true

class AddPersistenceTokenToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :persistence_token, :string
  end
end
