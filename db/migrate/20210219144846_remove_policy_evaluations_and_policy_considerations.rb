# frozen_string_literal: true

class RemovePolicyEvaluationsAndPolicyConsiderations < ActiveRecord::Migration[6.0]
  def change
    drop_table "policy_considerations" do |t|
      t.text "policy_question", null: false
      t.text "applicant_answer", null: false
      t.bigint "policy_evaluation_id"
      t.datetime "created_at", precision: 6, null: false
      t.datetime "updated_at", precision: 6, null: false
      t.index ["policy_evaluation_id"], name: "index_policy_considerations_on_policy_evaluation_id"
    end

    drop_table "policy_evaluations" do |t|
      t.bigint "planning_application_id"
      t.datetime "created_at", precision: 6, null: false
      t.datetime "updated_at", precision: 6, null: false
      t.integer "status", default: 0, null: false
      t.index ["planning_application_id"], name: "index_policy_evaluations_on_planning_application_id"
    end
  end
end
