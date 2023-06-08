# frozen_string_literal: true

class AddLocalAuthorityForeignKeyToConstraints < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :constraints, :local_authorities
  end
end
