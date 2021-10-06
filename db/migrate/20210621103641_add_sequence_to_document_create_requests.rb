# frozen_string_literal: true

class AddSequenceToDocumentCreateRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :document_create_requests, :sequence, :integer
  end
end
