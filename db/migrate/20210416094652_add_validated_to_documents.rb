class AddValidatedToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_column :documents, :validated, :boolean
    add_column :documents, :invalidated_document_reason, :text
  end
end
