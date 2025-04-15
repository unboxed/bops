# frozen_string_literal: true

class AddSubmissionUrlToLocalAuthority < ActiveRecord::Migration[7.2]
  def change
    add_column :local_authorities, :submission_url, :string
  end
end
