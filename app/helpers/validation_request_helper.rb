# frozen_string_literal: true

module ValidationRequestHelper
  def options_for_new_request_validations
    [
      ["replacement_document", "Request replacement documents"],
      ["create_document", "Request a new document"],
      ["other_validation", "Request other change to application"],
      ["red_line_boundary", "Request approval to a red line boundary change"]
    ]
  end

  def applicant_response(validation_request)
    if validation_request.is_a?(RedLineBoundaryChangeValidationRequest)
      if validation_request.approved?
        "Change to red line boundary has been approved by the applicant"
      elsif validation_request.approved == false
        validation_request.rejection_reason.to_s
      end
    elsif validation_request.class.name.include?("Other") && validation_request.closed?
      link_to("View response",
              planning_application_other_change_validation_request_path(validation_request.planning_application,
                                                                        validation_request))
    elsif validation_request.closed?
      link_to(validation_request.new_document.name.to_s,
              edit_planning_application_document_path(validation_request.planning_application,
                                                      validation_request.new_document.id.to_s))
    end
  end

  def display_request_status(validation_request)
    if validation_request.closed?
      "grey"
    elsif validation_request.overdue?
      "red"
    else
      "green"
    end
  end

  def request_closed_at(validation_request)
    validation_request.updated_at if validation_request.closed?
  end

  def cancel_confirmation_request_url(planning_application, validation_request)
    link_to "Cancel request",
            send("cancel_confirmation_planning_application_#{request_type(validation_request)}_path", planning_application,
                 validation_request)
  end

  def delete_confirmation_request_url(planning_application, validation_request)
    link_to "Delete request",
            send("planning_application_#{request_type(validation_request)}_path", planning_application, validation_request), method: :delete, data: { confirm: "Are you sure?" }
  end

  def cancel_request_url(planning_application, validation_request)
    send("cancel_planning_application_#{request_type(validation_request)}_path", planning_application,
         validation_request)
  end

  def document_url(document)
    link_to(document.name.to_s,
            edit_planning_application_document_path(document.planning_application, document.id))
  end

  private

  def request_type(validation_request)
    validation_request.class.name.underscore
  end
end
