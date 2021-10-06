# frozen_string_literal: true

class RenameDocumentCreateChangeRequests < ActiveRecord::Migration[6.1]
  def change
    rename_table :document_create_requests, :additional_document_validation_requests
  end
end
