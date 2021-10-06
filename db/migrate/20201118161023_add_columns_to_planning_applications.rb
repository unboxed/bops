# frozen_string_literal: true

class AddColumnsToPlanningApplications < ActiveRecord::Migration[6.0]
  def change
    add_column :planning_applications, :questions, :jsonb, null: true
    add_column :planning_applications, :audit_log, :jsonb, null: true
    add_column :planning_applications, :agent_first_name, :string, null: true
    add_column :planning_applications, :agent_last_name, :string, null: true
    add_column :planning_applications, :agent_phone, :string, null: true
    add_column :planning_applications, :agent_email, :string, null: true
    add_column :planning_applications, :applicant_first_name, :string
    add_column :planning_applications, :applicant_last_name, :string
    add_column :planning_applications, :applicant_email, :string, null: true
    add_column :planning_applications, :applicant_phone, :string, null: true
  end
end
