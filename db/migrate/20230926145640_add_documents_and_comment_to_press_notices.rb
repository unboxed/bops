# frozen_string_literal: true

class AddDocumentsAndCommentToPressNotices < ActiveRecord::Migration[7.0]
  def change
    add_column :press_notices, :comment, :text
    add_reference :documents, :press_notice, null: true, foreign_key: true
  end
end
