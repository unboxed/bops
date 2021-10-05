# frozen_string_literal: true

class RemoveDrawingName < ActiveRecord::Migration[6.0]
  def change
    remove_column :drawings, :name, default: "f", null: false
  end
end
