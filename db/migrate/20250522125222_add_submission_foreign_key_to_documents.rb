# frozen_string_literal: true

class AddSubmissionForeignKeyToDocuments < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_foreign_key :documents, :submissions, validate: false

    validate_foreign_key :documents, :submissions
  end
end
