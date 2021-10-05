# frozen_string_literal: true

class AddPublicToDocuments < ActiveRecord::Migration[6.0]
  def change
    add_column :documents, :publishable, :boolean, default: false
    add_column :documents, :referenced_in_decision_notice, :boolean, default: false
  end
end
