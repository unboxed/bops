# frozen_string_literal: true

class AddMissingLocalAuthoritiesForeignKeyToUsers < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :users, :local_authorities
  end
end
