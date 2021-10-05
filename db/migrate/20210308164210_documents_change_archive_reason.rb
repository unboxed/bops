# frozen_string_literal: true

class DocumentsChangeArchiveReason < ActiveRecord::Migration[6.0]
  def change
    change_column :documents, :archive_reason, :string
  end
end
