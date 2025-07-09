# frozen_string_literal: true

class AddForeignKeyOnCaseRecordUser < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key "case_records", "users", validate: false
  end
end
