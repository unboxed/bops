# frozen_string_literal: true

class RenameSubmissionDateToTargetDate < ActiveRecord::Migration[6.0]
  def change
    rename_column :planning_applications, :submission_date, :target_date
  end
end
