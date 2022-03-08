# frozen_string_literal: true

class AddReasonToReplacementDocumentValidationRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :replacement_document_validation_requests, :reason, :text
  end
end
