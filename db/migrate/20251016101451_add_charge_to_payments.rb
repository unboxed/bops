# frozen_string_literal: true

class AddChargeToPayments < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_reference :payments, :charge, null: false, index: {algorithm: :concurrently}
  end
end
