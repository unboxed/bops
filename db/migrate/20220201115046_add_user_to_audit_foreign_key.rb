# frozen_string_literal: true

class AddUserToAuditForeignKey < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :audits, :users
  end
end
