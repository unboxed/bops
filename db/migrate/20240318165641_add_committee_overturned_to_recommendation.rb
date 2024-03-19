# frozen_string_literal: true

class AddCommitteeOverturnedToRecommendation < ActiveRecord::Migration[7.1]
  def change
    add_column :recommendations, :committee_overturned, :boolean, default: false, null: false
  end
end
