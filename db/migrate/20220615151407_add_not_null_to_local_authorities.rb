# frozen_string_literal: true

class AddNotNullToLocalAuthorities < ActiveRecord::Migration[6.1]
  def change
    change_column_null :local_authorities, :signatory_name, false
    change_column_null :local_authorities, :signatory_job_title, false
    change_column_null :local_authorities, :enquiries_paragraph, false
    change_column_null :local_authorities, :email_address, false
    change_column_null :local_authorities, :feedback_email, false
  end
end
