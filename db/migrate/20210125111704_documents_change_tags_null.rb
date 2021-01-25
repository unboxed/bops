class DocumentsChangeTagsNull < ActiveRecord::Migration[6.0]
  def change
    change_column_null(:documents, :tags, true )
  end
end
