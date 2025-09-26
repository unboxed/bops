# frozen_string_literal: true

class CreatePlanningApplicationConstraintConsultees < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    create_table :planning_application_constraint_consultees do |t|
      t.references :planning_application_constraint, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.references :consultee, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.timestamps
    end

    add_index :planning_application_constraint_consultees,
      [:planning_application_constraint_id, :consultee_id],
      unique: true,
      name: "ix_pacc_on_constraint_id_and_consultee_id",
      algorithm: :concurrently

    add_index :planning_application_constraint_consultees,
      :consultee_id,
      name: "ix_pacc_on_consultee_id",
      algorithm: :concurrently

    safety_assured do
      execute <<~SQL.squish
        INSERT INTO planning_application_constraint_consultees
          (planning_application_constraint_id, consultee_id, created_at, updated_at)
        SELECT id, consultee_id, NOW(), NOW()
        FROM planning_application_constraints
        WHERE consultee_id IS NOT NULL
      SQL
    end
  end

  def down
    drop_table :planning_application_constraint_consultees
  end
end
