# frozen_string_literal: true

class AddSubmissionReferenceToDocuments < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_reference :documents, :submission, null: true, index: {algorithm: :concurrently}
  end
end
