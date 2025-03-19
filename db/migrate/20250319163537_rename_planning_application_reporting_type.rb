# frozen_string_literal: true

class RenamePlanningApplicationReportingType < ActiveRecord::Migration[7.2]
  def change
    add_column :planning_applications, :reporting_type_code, :string

    up_only do
      safety_assured do
        execute <<~SQL
          UPDATE planning_applications
          SET reporting_type_code = reporting_type;
        SQL
      end
    end
  end
end
