# frozen_string_literal: true

class AddReviewerGroupEmailToLocalAuthority < ActiveRecord::Migration[6.1]
  def change
    add_column :local_authorities, :reviewer_group_email, :string
  end
end
