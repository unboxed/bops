# frozen_string_literal: true

class AddFeedbackToPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :planning_applications, :feedback, :jsonb, default: {}
  end
end
