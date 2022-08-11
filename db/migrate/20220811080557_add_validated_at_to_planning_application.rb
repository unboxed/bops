# frozen_string_literal: true

class AddValidatedAtToPlanningApplication < ActiveRecord::Migration[6.1]
  def up
    add_column :planning_applications, :validated_at, :datetime

    PlanningApplication.all.find_each do |p|
      p.update!(validated_at: p.documents_validated_at&.to_datetime)
    end
  end

  def down
    remove_column :planning_applications, :validated_at, :datetime
  end
end
