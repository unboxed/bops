# frozen_string_literal: true

class AddPublishedAtToPlanningApplications < ActiveRecord::Migration[7.1]
  def change
    add_column :planning_applications, :published_at, :datetime

    up_only do
      PlanningApplication.where(make_public: true).find_each do |application|
        application.update(published_at: application.validated_at)
      end
    end
  end
end
