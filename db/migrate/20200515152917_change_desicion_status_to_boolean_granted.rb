# frozen_string_literal: true

class ChangeDesicionStatusToBooleanGranted < ActiveRecord::Migration[6.0]
  def change
    remove_column :decisions, :status
    add_column :decisions, :granted, :boolean, null: false, default: false
  end
end
