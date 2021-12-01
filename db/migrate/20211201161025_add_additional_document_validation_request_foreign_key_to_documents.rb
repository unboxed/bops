# frozen_string_literal: true

class AddAdditionalDocumentValidationRequestForeignKeyToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_reference :documents, :additional_document_validation_request, foreign_key: true
  end
end
