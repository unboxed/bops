# frozen_string_literal: true

class DropReplyToNotifyIdOnLocalAuthorities < ActiveRecord::Migration[7.1]
  def change
    remove_column :local_authorities, :reply_to_notify_id, :string
  end
end
