# frozen_string_literal: true

class AddPolicyConsiderations < ActiveRecord::Migration[6.0]
  def change
    create_table :policy_considerations do |t|
      t.text :policy_question, null: false
      t.text :applicant_answer, null: false

      t.references :policy_evaluation

      t.timestamps
    end
  end
end
