# frozen_string_literal: true

class RemoveAuditLogFromPlanningApplications < ActiveRecord::Migration[7.0]
  def change
    remove_column :planning_applications, :audit_log, :jsonb
  end
end
