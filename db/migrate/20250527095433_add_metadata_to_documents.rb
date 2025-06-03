# frozen_string_literal: true

class AddMetadataToDocuments < ActiveRecord::Migration[7.2]
  def change
    add_column :documents, :metadata, :jsonb, null: false, default: {}
  end
end
