# frozen_string_literal: true

class AddReportingTypeReferenceToPlanningApplications < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    safety_assured do
      remove_column :planning_applications, :reporting_type, :string
    end

    add_reference :planning_applications, :reporting_type, null: true, index: {algorithm: :concurrently}

    up_only do
      PlanningApplication.where.not(reporting_type_code: nil).find_each do |planning_application|
        planning_application.reporting_type_id = ReportingType.find_by(code: planning_application.reporting_type_code).id
      end
    end
  end
end
