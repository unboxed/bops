# frozen_string_literal: true

class RenameConstraintsNameToType < ActiveRecord::Migration[7.0]
  def change
    rename_column :constraints, :name, :type
  end
end
