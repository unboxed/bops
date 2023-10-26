# frozen_string_literal: true

class DropSelectedColumnFromConsultees < ActiveRecord::Migration[7.0]
  def change
    remove_column :consultees, :selected, :boolean, default: true, null: false
  end
end
