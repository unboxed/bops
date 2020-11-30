class AddDrawingDocumentStatus < ActiveRecord::Migration[6.0]
  def change
    add_column :drawings, :document_status, :integer, default: 0
  end
end
