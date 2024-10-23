# frozen_string_literal: true

class AddNotifyErrorStatusToLocalAuthority < ActiveRecord::Migration[7.1]
  def change
    add_column :local_authorities, :notify_error_status, :string, null: true
  end
end
