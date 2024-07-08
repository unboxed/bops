# frozen_string_literal: true

class AddDefaultToApplicationTypeDocumentTags < ActiveRecord::Migration[7.1]
  def change
    change_column_null :application_types, :document_tags, false, {} # rubocop:disable Rails/BulkChangeTable
    change_column_default :application_types, :document_tags, from: nil, to: {}
  end
end
