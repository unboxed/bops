# frozen_string_literal: true

class RenameDrawingsToDocuments < ActiveRecord::Migration[6.0]
  def change
    rename_table :drawings, :documents
  end
end
