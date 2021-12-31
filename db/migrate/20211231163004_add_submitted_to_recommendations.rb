# frozen_string_literal: true

class AddSubmittedToRecommendations < ActiveRecord::Migration[6.1]
  def change
    add_column :recommendations, :submitted, :boolean
  end
end
