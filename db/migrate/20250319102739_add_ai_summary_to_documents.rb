# frozen_string_literal: true

class AddAiSummaryToDocuments < ActiveRecord::Migration[7.2]
  def change
    add_column :documents, :ai_summary, :text
  end
end
