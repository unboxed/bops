# frozen_string_literal: true

class AddUserToCaseRecord < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_reference :case_records, :user, null: true, index: {algorithm: :concurrently}
  end
end
