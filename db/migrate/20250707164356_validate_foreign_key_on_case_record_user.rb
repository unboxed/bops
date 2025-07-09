# frozen_string_literal: true

class ValidateForeignKeyOnCaseRecordUser < ActiveRecord::Migration[7.2]
  def change
    validate_foreign_key "case_records", "users"
  end
end
