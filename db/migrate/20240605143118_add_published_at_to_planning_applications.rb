# frozen_string_literal: true

class AddPublishedAtToPlanningApplications < ActiveRecord::Migration[7.1]
  def change
    add_column :planning_applications, :published_at, :datetime

    up_only do
      PlanningApplication.find_each(make_public: true) do |application|
        application.update(published_at: application.validated_at)
      end
    end
  end
end
