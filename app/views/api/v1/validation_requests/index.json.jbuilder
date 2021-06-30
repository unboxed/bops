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

  json.red_line_boundary_change_validation_requests @planning_application.red_line_boundary_change_validation_requests do |red_line_boundary_change_validation_request|
    json.extract! red_line_boundary_change_validation_request,
                  :id,
                  :state,
                  :response_due,
                  :new_geojson,
                  :reason,
                  :approved,
                  :days_until_response_due
    json.type "red_line_boundary_change_validation_request"
  end

  json.replacement_document_validation_requests @planning_application.replacement_document_validation_requests do |replacement_document_validation_request|
    json.extract! replacement_document_validation_request,
                  :id,
                  :state,
                  :response_due,
                  :days_until_response_due
    json.old_document do
      json.name replacement_document_validation_request.old_document.file.filename
      json.invalid_document_reason replacement_document_validation_request.old_document.invalidated_document_reason
    end

    json.new_document do
      if replacement_document_validation_request.new_document
        json.name replacement_document_validation_request.new_document.file.filename
        json.url replacement_document_validation_request.new_document.file.representation(resize_to_limit: [1000, 1000]).processed.url
      end
    end
    json.type "replacement_document_validation_request"
  end

  json.additional_document_validation_requests @planning_application.additional_document_validation_requests do |additional_document_validation_request|
    json.extract! additional_document_validation_request,
                  :id,
                  :state,
                  :response_due,
                  :days_until_response_due,
                  :document_request_type,
                  :document_request_reason

    json.new_document do
      if additional_document_validation_request.new_document
        json.name additional_document_validation_request.new_document.file.filename
        json.url additional_document_validation_request.new_document.file.representation(resize_to_limit: [1000, 1000]).processed.url
      end
    end
    json.type "additional_document_validation_request"
  end
<<<<<<< HEAD

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
=======
>>>>>>> b408ddc (Rename ChangeRequest to ValidationRequest)
end
