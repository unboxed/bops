# frozen_string_literal: true

class RemoveAdditionalDocumentValidationRequestNewDocumentForeignKey < ActiveRecord::Migration[6.1]
  def change
    remove_reference :additional_document_validation_requests, :new_document
  end
end
