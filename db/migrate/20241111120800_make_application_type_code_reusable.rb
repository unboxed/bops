# frozen_string_literal: true

class MakeApplicationTypeCodeReusable < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    reversible do |dir|
      dir.up do
        remove_index :application_types, [:code], unique: true, algorithm: :concurrently
        add_index :application_types, [:code], unique: true, where: "status <> 'retired'", algorithm: :concurrently
      end

      dir.down do
        remove_index :application_types, [:code], unique: true, where: "status <> 'retired'", algorithm: :concurrently
        add_index :application_types, [:code], unique: true, algorithm: :concurrently
      end
    end
  end
end
