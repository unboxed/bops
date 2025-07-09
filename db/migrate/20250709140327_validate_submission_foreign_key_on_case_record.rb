# frozen_string_literal: true

class ValidateSubmissionForeignKeyOnCaseRecord < ActiveRecord::Migration[7.2]
  def change
    validate_foreign_key :case_records, :submissions
  end
end
