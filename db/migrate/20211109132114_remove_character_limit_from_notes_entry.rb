# frozen_string_literal: true

class RemoveCharacterLimitFromNotesEntry < ActiveRecord::Migration[6.1]
  # rubocop:disable Rails/BulkChangeTable
  def change
    change_column :notes, :entry, :string, limit: nil
    change_column :notes, :entry, :text
  end
  # rubocop:enable Rails/BulkChangeTable
end
