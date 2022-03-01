# frozen_string_literal: true

class AddReplacementDocumentValidationRequestForeignKeyToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_reference :documents, :replacement_document_validation_request, foreign_key: true
  end
end
