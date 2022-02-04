# frozen_string_literal: true

class AddDeterminationDateToPlanningApplications < ActiveRecord::Migration[6.1]
  class PlanningApplication < ApplicationRecord; end

  def up
    add_column :planning_applications, :determination_date, :datetime

    PlanningApplication.find_each do |planning_application|
      if (determined_at = planning_application.determined_at)
        planning_application.update(determination_date: determined_at)
      end
    end
  end

  def down
    remove_column :planning_applications, :determination_date, :datetime
  end
end
