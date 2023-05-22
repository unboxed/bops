# frozen_string_literal: true

class CreatePlanningApplicationConstraint < ActiveRecord::Migration[7.0]
  def change
    create_table :planning_application_constraints do |t|
      t.references :planning_application, foreign_key: true
      t.references :planning_application_constraints_query, foreign_key: true, null: true
      t.references :constraint, foreign_key: true

      t.timestamps
    end

    up_only do
      constraints = PlanningApplication.pluck(:id, :old_constraints)

      constraints.each do |planning_application_id, names|
        names.each do |name|
          constraint = Constraint.find_by!(name:)
          PlanningApplicationConstraint.create!(
            constraint:, planning_application: PlanningApplication.find(planning_application_id)
          )
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, ArgumentError => e
          raise "Could not create constraint with name: '#{name}' and planning_application_id: '#{planning_application_id}' with error: #{e.message}" # rubocop:disable Layout/LineLength
        end
      end
    end
  end
end
