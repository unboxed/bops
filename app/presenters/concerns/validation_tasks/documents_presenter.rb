# frozen_string_literal: true

module ValidationTasks
  extend ActiveSupport::Concern

  class DocumentsPresenter < PlanningApplicationPresenter
    attr_reader :document

    def initialize(template, planning_application, document)
      super(template, planning_application)

      @document = document
    end

    def task_list_row
      html = tag.span class: "app-task-list__task-name" do
        concat document_validate_link
      end

      html.concat document_status_tag
    end

    private

    def document_validate_link
      case document_status
      when "Valid", "Not checked yet"
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
        raise ArgumentError, "Status: #{document_status} is not a valid option"
      end
    end

    def validate_document_link_text
      "Validate document - #{truncate document.name.to_s, length: 25}"
    end

    def document_status
      status = if document.validated?
                 "Valid"
               elsif document.replacement_document_validation_request.try(:open_or_pending?)
                 "Invalid"
               else
                 "Not checked yet"
               end

      raise "Status: #{status} is not included in the permitted list" unless STATUSES.include?(status)

      status
    end

    def document_status_tag
      classes = ["govuk-tag govuk-tag--#{document_status_tag_colour} app-task-list__task-tag"]

      tag.strong class: classes do
        document_status
      end
    end

    def document_status_tag_colour
      STATUS_COLOURS[document_status.to_sym]
    end
  end
end
