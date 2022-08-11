# frozen_string_literal: true

class DropDocumentsValidatedAtToPlanningApplication < ActiveRecord::Migration[6.1]
  def up
    remove_column :planning_applications, :documents_validated_at, :datetime
  end

  def down
    add_column :planning_applications, :documents_validated_at, :date

    PlanningApplication.all.find_each do |p|
      p.update!(documents_validated_at: p.validated_at&.to_datetime)
    end
  end
end
