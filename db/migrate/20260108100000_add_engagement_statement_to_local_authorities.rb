# frozen_string_literal: true

class AddEngagementStatementToLocalAuthorities < ActiveRecord::Migration[7.2]
  def change
    add_column :local_authorities, :engagement_statement, :text
  end
end
