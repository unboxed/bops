# frozen_string_literal: true

class AddRedactedToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_column :documents, :redacted, :boolean, default: false

    Document.find_each do |document|
      document.update!(redacted: false)
    end

    change_column_null :documents, :redacted, false
  end
end
