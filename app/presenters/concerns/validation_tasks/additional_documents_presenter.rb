# frozen_string_literal: true

module ValidationTasks
  extend ActiveSupport::Concern

  class AdditionalDocumentsPresenter < PlanningApplicationPresenter
    def task_list_row
      html = tag.span class: "app-task-list__task-name" do
        concat link_to "Check required documents are on application",
                       validation_documents_planning_application_path(planning_application), class: "govuk-link"
      end

      html.concat validation_item_tag
    end

    private

    def validation_item_status
      status = if planning_application.additional_document_validation_requests.open_or_pending.any?
                 "Invalid"
               elsif planning_application.documents_missing == false
                 "Valid"
               else
                 "Not checked yet"
               end

      raise "Status: #{status} is not included in the permitted list" unless STATUSES.include?(status)

      status
    end
  end
end
