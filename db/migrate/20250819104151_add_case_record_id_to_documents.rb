# frozen_string_literal: true

class AddCaseRecordIdToDocuments < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_reference :documents, :case_record, type: :uuid, null: true, index: {algorithm: :concurrently}
  end
end
