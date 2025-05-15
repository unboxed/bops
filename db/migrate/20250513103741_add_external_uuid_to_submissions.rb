# frozen_string_literal: true

class AddExternalUuidToSubmissions < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :submissions, :external_uuid, :string
    add_index :submissions, :external_uuid, unique: true, algorithm: :concurrently
  end
end
