# frozen_string_literal: true

json.data do
  json.description_change_validation_requests @planning_application
    .validation_requests.description_changes do |description_change_validation_request|
    json.extract! description_change_validation_request,
      :id,
      :state,
      :response_due,
      :proposed_description,
      :previous_description,
      :applicant_rejection_reason,
      :applicant_approved,
      :days_until_response_due,
      :cancel_reason,
      :cancelled_at
    json.type "description_change_validation_request"
  end

  json.red_line_boundary_change_validation_requests @planning_application
    .validation_requests.red_line_boundary_changes do |red_line_boundary_change_validation_request|
    json.extract! red_line_boundary_change_validation_request,
      :id,
      :state,
      :response_due,
      :new_geojson,
      :reason,
      :applicant_rejection_reason,
      :applicant_approved,
      :days_until_response_due,
      :cancel_reason,
      :cancelled_at
    json.type "red_line_boundary_change_validation_request"
  end

  json.replacement_document_validation_requests @planning_application
    .validation_requests.replacement_documents do |replacement_document_validation_request|
    json.extract! replacement_document_validation_request,
      :id,
      :state,
      :response_due,
      :days_until_response_due,
      :cancel_reason,
      :cancelled_at
    json.old_document do
      json.name replacement_document_validation_request.old_document.file.filename
      json.invalid_document_reason replacement_document_validation_request.invalidated_document_reason
    end

    json.new_document do
      if replacement_document_validation_request.new_document
        json.name replacement_document_validation_request.new_document.file.filename
        json.url replacement_document_validation_request
          .new_document.file.representation(resize_to_limit: [1000, 1000]).processed.url
      end
    end
    json.type "replacement_document_validation_request"
  end

  json.additional_document_validation_requests @planning_application
    .validation_requests.additional_documents do |additional_document_validation_request|
    json.extract! additional_document_validation_request,
      :id,
      :state,
      :response_due,
      :days_until_response_due,
      :document_request_type,
      :reason,
      :cancel_reason,
      :cancelled_at

    json.documents additional_document_validation_request.additional_documents do |document|
      json.name document.file.filename
      json.url document.file.representation(resize_to_limit: [1000, 1000]).processed.url
      json.extract! document
    end

    json.type "additional_document_validation_request"
  end

  json.fee_change_validation_requests @planning_application
    .validation_requests.fee_changes do |other_change_validation_request|
    json.extract! other_change_validation_request,
      :id,
      :state,
      :response_due,
      :applicant_response,
      :reason,
      :suggestion,
      :days_until_response_due,
      :cancel_reason,
      :cancelled_at
    json.type "other_change_validation_request"
  end

  json.other_change_validation_requests @planning_application
    .validation_requests.other_changes do |other_change_validation_request|
    json.extract! other_change_validation_request,
      :id,
      :state,
      :response_due,
      :applicant_response,
      :reason,
      :suggestion,
      :days_until_response_due,
      :cancel_reason,
      :cancelled_at
    json.type "other_change_validation_request"
  end
end
