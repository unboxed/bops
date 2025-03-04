class AddAiDescriptionToDocuments < ActiveRecord::Migration[7.2]
  def change
    add_column :documents, :ai_description, :text
  end
end
