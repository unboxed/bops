class CreatePolicyEvaluations < ActiveRecord::Migration[6.0]
  def change
    create_table :policy_evaluations do |t|
      t.boolean :requirements_met, default: false, null: false
      t.references :planning_application

      t.timestamps
    end
  end
end
