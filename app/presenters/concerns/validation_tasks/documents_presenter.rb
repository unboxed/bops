# frozen_string_literal: true

module ValidationTasks
  extend ActiveSupport::Concern

  class DocumentsPresenter < PlanningApplicationPresenter
    include DocumentHelper
    attr_reader :document

    def initialize(template, planning_application, document)
      super(template, planning_application)

      @document = document
    end

    def task_list_row
      html = tag.span class: "app-task-list__task-name" do
        concat validate_link
      end

      html.concat validation_item_tag
    end

    private

    def validate_link
      case validation_item_status
      when "Valid", "Not checked yet", "Updated"
        link_to validate_document_link_text,
                edit_planning_application_document_path(
                  planning_application, document, validate: "yes"
                ), class: "govuk-link"
      when "Invalid"
        link_to validate_document_link_text,
                planning_application_replacement_document_validation_request_path(
                  planning_application, document.replacement_document_validation_request
                ), class: "govuk-link"
      else
        raise ArgumentError, "Status: #{validation_item_status} is not a valid option"
      end
    end

    def validate_document_link_text
      "Check document - #{truncate reference_or_file_name(document).to_s, length: 25}"
    end

    def validation_item_status
      status = if document.validated?
                 "Valid"
               elsif document.replacement_document_validation_request.try(:open_or_pending?)
                 "Invalid"
               elsif replacement_document_validation_request(document)
                 "Updated"
               else
                 "Not checked yet"
               end

      raise "Status: #{status} is not included in the permitted list" unless STATUSES.include?(status)

      status
    end

    def replacement_document_validation_request(document)
      @replacement_document_validation_request ||=
        ReplacementDocumentValidationRequest.find_by(new_document_id: document.id)
    end
  end
end
