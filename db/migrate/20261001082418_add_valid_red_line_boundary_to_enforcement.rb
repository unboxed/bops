# frozen_string_literal: true

class AddValidRedLineBoundaryToEnforcement < ActiveRecord::Migration[8.1]
  def change
    add_column :enforcements, :valid_red_line_boundary, :boolean, null: false, default: false
  end
end
