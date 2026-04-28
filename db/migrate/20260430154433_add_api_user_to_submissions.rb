# frozen_string_literal: true

class AddApiUserToSubmissions < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_reference :submissions, :api_user, null: true, index: false
    add_index :submissions, :api_user_id, algorithm: :concurrently, name: "ix_submissions_on_api_user_id"
  end
end
