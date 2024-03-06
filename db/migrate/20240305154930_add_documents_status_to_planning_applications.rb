# frozen_string_literal: true

class AddDocumentsStatusToPlanningApplications < ActiveRecord::Migration[7.1]
  class Document < ActiveRecord::Base; end

  class PlanningApplication < ActiveRecord::Base
    has_many :documents

    default_scope -> { preload(:documents) }
  end

  def change
    add_column :planning_applications, :documents_status, :string

    up_only do
      PlanningApplication.find_each do |pa|
        if pa.documents.any?(&:redacted?)
          pa.update_column(:documents_status, "complete")
        else
          pa.update_column(:documents_status, "not_started")
        end
      end

      change_column_default(:planning_applications, :documents_status, "not_started")
      change_column_null(:planning_applications, :documents_status, false)
    end
  end
end
