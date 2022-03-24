# frozen_string_literal: true

class AddDocumentsMissingToPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :planning_applications, :documents_missing, :boolean

    up_only do
      PlanningApplication.find_each do |planning_application|
        if planning_application.additional_document_validation_requests.open_or_pending.any?
          planning_application.update!(documents_missing: true)
        else
          planning_application.update!(documents_missing: false)
        end
      end
    end
  end
end
