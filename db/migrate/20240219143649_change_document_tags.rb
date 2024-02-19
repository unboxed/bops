# frozen_string_literal: true

class ChangeDocumentTags < ActiveRecord::Migration[7.1]
  def up
    add_column :documents, :tags_temp, :string, array: true, default: []

    Document.find_each do |document|
      document.update(tags_temp: document.tags)
    end

    remove_column :documents, :tags
    rename_column :documents, :tags_temp, :tags
  end

  def down
    add_column :documents, :tags_temp, :jsonb, default: []

    Document.find_each do |document|
      document.update(tags_temp: document.tags)
    end

    remove_column :documents, :tags
    rename_column :documents, :tags_temp, :tags
  end
end
