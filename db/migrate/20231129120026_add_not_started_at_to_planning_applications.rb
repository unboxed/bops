# frozen_string_literal: true

class AddNotStartedAtToPlanningApplications < ActiveRecord::Migration[7.0]
  def up
    add_column :planning_applications, :not_started_at, :datetime

    execute <<-SQL
      UPDATE planning_applications
      SET not_started_at = created_at
    SQL
  end

  def down
    remove_column :planning_applications, :not_started_at, :datetime
  end
end
