class AddNotifyIdToNeighbourLetters < ActiveRecord::Migration[7.0]
  def change
    change_table :neighbour_letters, bulk: true do |t|
      t.string :notify_id
      t.string :status
      t.string :status_updated_at
    end
  end
end
