# frozen_string_literal: true

class AddUniqueValidationOnInformative < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :informatives, [:title, :informative_set_id], unique: true, algorithm: :concurrently
    add_index :informatives, [:text, :informative_set_id], unique: true, algorithm: :concurrently
  end
end
