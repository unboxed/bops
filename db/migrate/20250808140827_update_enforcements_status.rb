# frozen_string_literal: true

class UpdateEnforcementsStatus < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    up_only do
      Enforcement.where(status: nil).in_batches do |batch|
        batch.update_all(
          status: "not_started",
          not_started_at: Arel.sql("created_at")
        )
      end
    end
  end
end
