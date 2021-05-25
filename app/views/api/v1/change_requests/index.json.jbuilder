# frozen_string_literal: true

json.data do
  json.description_change_requests @planning_application.description_change_requests do |description_change_request|
    json.extract! description_change_request,
                  :id,
                  :state,
                  :response_due,
                  :proposed_description,
                  :previous_description,
                  :rejection_reason,
                  :approved,
                  :days_until_response_due
    json.type "description_change_request"
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
end
