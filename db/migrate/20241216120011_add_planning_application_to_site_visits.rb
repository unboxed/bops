# frozen_string_literal: true

class AddPlanningApplicationToSiteVisits < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    safety_assured do
      add_reference :site_visits, :planning_application, null: true, foreign_key: true, index: {algorithm: :concurrently}

      up_only do
        execute <<~SQL
          UPDATE site_visits
          SET planning_application_id = consultations.planning_application_id
          FROM consultations
          WHERE consultations.id = site_visits.consultation_id
        SQL

        change_column_null :site_visits, :planning_application_id, false
      end
    end
  end
end
