# frozen_string_literal: true

class ChangeGrantedToStatusOnDecisions < ActiveRecord::Migration[6.0]
  def change
    remove_column :decisions, :granted, :boolean, null: false, default: false
    add_column :decisions, :status, :integer, default: 0, null: false
  end
end
