class AddColumnToAdditionalDocumentValidationRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :additional_document_validation_requests, :notified_at, :date
  end
end
