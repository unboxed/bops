# frozen_string_literal: true

class AddMoreFieldsToConstraints < ActiveRecord::Migration[7.0]
  def up
    change_table :planning_application_constraints do |t|
      t.column :data, :jsonb
      t.column :metadata, :jsonb
      t.column :identified, :boolean, null: false, default: false
      t.column :identified_by, :string
    end

    PlanningApplicationConstraint.find_each do |record|
      record.update!(identified: true, identified_by: "PlanX")
    end
  end

  def down
    change_table :planning_application_constraints do |t|
      t.remove :data
      t.remove :metadata
      t.remove :identified
      t.remove :identified_by
    end
  end
end
