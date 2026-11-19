# frozen_string_literal: true

class AddAddressSearchToEnforcements < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    sql = <<~SQL.squish
      to_tsvector('simple',
        COALESCE(address_1, '') || ' ' ||
        COALESCE(address_2, '') || ' ' ||
        COALESCE(town, '') || ' ' ||
        COALESCE(county, '') || ' ' ||
        COALESCE(postcode, '')
      )
    SQL

    add_column :enforcements, :address_search, :tsvector, as: sql, stored: true
    add_index :enforcements, :address_search, using: :gin, algorithm: :concurrently
  end
end
