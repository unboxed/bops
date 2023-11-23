# frozen_string_literal: true

class AddMissingLocalAuthorityForeignKeyOnApiUsers < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :api_users, :local_authorities
  end
end
