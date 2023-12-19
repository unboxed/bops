# frozen_string_literal: true

class ChangeLocalAuthorityColumnNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null(:local_authorities, :email_address, true)
    change_column_null(:local_authorities, :signatory_name, true)
    change_column_null(:local_authorities, :signatory_job_title, true)
    change_column_null(:local_authorities, :enquiries_paragraph, true)
    change_column_null(:local_authorities, :feedback_email, true)
  end
end
