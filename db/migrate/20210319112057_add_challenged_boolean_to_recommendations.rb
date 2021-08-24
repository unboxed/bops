class AddChallengedBooleanToRecommendations < ActiveRecord::Migration[6.1]
  def change
    add_column :recommendations, :challenged, :boolean
  end
end
