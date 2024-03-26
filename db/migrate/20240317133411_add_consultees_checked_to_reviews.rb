# frozen_string_literal: true

class AddConsulteesCheckedToReviews < ActiveRecord::Migration[7.1]
  def change
    add_column :reviews, :consultees_checked, :boolean, default: false, null: false
  end
end
