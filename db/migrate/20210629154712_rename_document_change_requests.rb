class RenameDocumentChangeRequests < ActiveRecord::Migration[6.1]
  def change
    rename_table :document_change_requests, :replacement_document_validation_requests
  end
end
