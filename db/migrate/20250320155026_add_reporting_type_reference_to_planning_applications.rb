# frozen_string_literal: true

class AddReportingTypeReferenceToPlanningApplications < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  class PlanningApplication < ActiveRecord::Base; end
  class ReportingType < ActiveRecord::Base; end

  def change
    safety_assured do
      remove_column :planning_applications, :reporting_type, :string, if_exists: true
    end

    add_reference :planning_applications, :reporting_type, null: true, index: {algorithm: :concurrently}

    up_only do
      reporting_types = ReportingType.pluck(:code, :id).to_h

      PlanningApplication.all.find_each do |planning_application|
        planning_application.reporting_type_id = reporting_types[planning_application.reporting_type_code]
      end
    end
  end
end
