# frozen_string_literal: true

class AddApplicationTypeToEnforcement < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_reference :enforcements, :application_type, null: false, index: {algorithm: :concurrently}
  end
end
