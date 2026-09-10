# frozen_string_literal: true

class MakeAuditPlanningApplicationNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :audits, :planning_application_id, true
  end
end
