# frozen_string_literal: true

json.data do
  json.description_change_validation_requests @planning_application.description_change_validation_requests do |description_change_validation_request|
    json.extract! description_change_validation_request,
                  :id,
                  :state,
                  :response_due,
                  :proposed_description,
                  :previous_description,
                  :rejection_reason,
                  :approved,
                  :days_until_response_due
    json.type "description_change_validation_request"
  end

  json.red_line_boundary_change_requests @planning_application.red_line_boundary_change_requests do |red_line_boundary_change_request|
    json.extract! red_line_boundary_change_request,
                  :id,
                  :state,
                  :response_due,
                  :new_geojson,
                  :reason,
                  :approved,
                  :days_until_response_due
    json.type "red_line_boundary_change_request"
  end

  json.document_change_requests @planning_application.document_change_requests do |document_change_request|
    json.extract! document_change_request,
                  :id,
                  :state,
                  :response_due,
                  :days_until_response_due
    json.old_document do
      json.name document_change_request.old_document.file.filename
      json.invalid_document_reason document_change_request.old_document.invalidated_document_reason
    end

    json.new_document do
      if document_change_request.new_document
        json.name document_change_request.new_document.file.filename
        json.url document_change_request.new_document.file.representation(resize_to_limit: [1000, 1000]).processed.url
      end
    end
    json.type "document_change_request"
  end

  json.document_create_requests @planning_application.document_create_requests do |document_create_request|
    json.extract! document_create_request,
                  :id,
                  :state,
                  :response_due,
                  :days_until_response_due,
                  :document_request_type,
                  :document_request_reason

    json.new_document do
      if document_create_request.new_document
        json.name document_create_request.new_document.file.filename
        json.url document_create_request.new_document.file.representation(resize_to_limit: [1000, 1000]).processed.url
      end
    end
    json.type "document_create_request"
  end

  json.other_change_validation_requests @planning_application.other_change_validation_requests do |other_change_validation_request|
    json.extract! other_change_validation_request,
                  :id,
                  :state,
                  :response_due,
                  :response,
                  :summary,
                  :suggestion,
                  :days_until_response_due
    json.type "other_change_validation_request"
  end
end
