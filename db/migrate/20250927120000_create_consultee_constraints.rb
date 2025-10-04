# frozen_string_literal: true

class CreateConsulteeConstraints < ActiveRecord::Migration[8.0]
  def change
    create_table :consultee_constraints do |t|
      t.references :consultee, null: false, foreign_key: {to_table: :contacts, on_delete: :cascade}
      t.references :constraint, null: false, foreign_key: {on_delete: :cascade}

      t.timestamps
    end

    add_index :consultee_constraints, [:consultee_id, :constraint_id], unique: true, name: "index_consultee_constraints_on_consultee_and_constraint"
  end
end
