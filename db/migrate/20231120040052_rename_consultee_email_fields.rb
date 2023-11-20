# frozen_string_literal: true

class RenameConsulteeEmailFields < ActiveRecord::Migration[7.0]
  def change
    rename_column :consultations, :consultee_email_subject, :consultee_message_subject
    rename_column :consultations, :consultee_email_body, :consultee_message_body
  end
end
