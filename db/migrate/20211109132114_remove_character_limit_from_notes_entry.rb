# frozen_string_literal: true

class RemoveCharacterLimitFromNotesEntry < ActiveRecord::Migration[6.1]
  def change
    change_column :notes, :entry, :string, limit: nil
    change_column :notes, :entry, :text
  end
end
