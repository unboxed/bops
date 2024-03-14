class AddDetailsToCommitteeDecision < ActiveRecord::Migration[7.1]
  def change
    change_table :committee_decisions, bulk: true do |t|
      t.string :location
      t.string :link
      t.string :time
      t.datetime :late_comments_deadline
      t.text :notification_content
    end
  end
end
