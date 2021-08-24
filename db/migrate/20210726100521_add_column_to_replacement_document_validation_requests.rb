class AddColumnToReplacementDocumentValidationRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :replacement_document_validation_requests, :notified_at, :date
  end
end
