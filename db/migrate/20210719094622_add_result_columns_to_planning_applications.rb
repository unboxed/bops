# frozen_string_literal: true

class AddResultColumnsToPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :planning_applications, :result_flag, :string
    add_column :planning_applications, :result_heading, :text
    add_column :planning_applications, :result_description, :text
    add_column :planning_applications, :result_override, :string
    add_reference :planning_applications, :api_user, foreign_key: true
  end
end
