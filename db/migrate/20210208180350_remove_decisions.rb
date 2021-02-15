class RemoveDecisions < ActiveRecord::Migration[6.0]
  def change
    drop_table "decisions" do |t|
      t.datetime "decided_at"
      t.bigint "planning_application_id", null: false
      t.bigint "user_id", null: false
      t.datetime "created_at", precision: 6, null: false
      t.datetime "updated_at", precision: 6, null: false
      t.integer "status"
      t.text "public_comment"
      t.text "private_comment"
      t.index %w[planning_application_id], name: "index_decisions_on_planning_application_id"
      t.index %w[user_id], name: "index_decisions_on_user_id"
    end
  end
end
