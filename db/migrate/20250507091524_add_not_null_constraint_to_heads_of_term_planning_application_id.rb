# frozen_string_literal: true

class AddNotNullConstraintToHeadsOfTermPlanningApplicationId < ActiveRecord::Migration[7.2]
  def up
    safety_assured do
      # Delete any orphan heads_of_term records
      execute <<~SQL
        DELETE FROM heads_of_terms
        WHERE planning_application_id IS NULL
      SQL

      change_column_null :heads_of_terms, :planning_application_id, false
    end
  end

  def down
    change_column_null :heads_of_terms, :planning_application_id, true
  end
end
