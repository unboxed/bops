# frozen_string_literal: true

class AddSubmissionForeignKeyToCaseRecord < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :case_records, :submissions, validate: false
  end
end
