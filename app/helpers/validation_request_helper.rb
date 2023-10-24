# frozen_string_literal: true

module ValidationRequestHelper
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

  def edit_request_url(planning_application, validation_request, classname: nil)
    link_to "Edit request",
      send("edit_planning_application_#{request_type(validation_request)}_path", planning_application,
        validation_request), class: classname
  end

  def cancel_confirmation_request_url(planning_application, validation_request, classname: nil)
    link_to "Cancel request",
      send("cancel_confirmation_planning_application_#{request_type(validation_request)}_path",
        planning_application, validation_request), class: classname
  end

  def delete_confirmation_request_url(planning_application, validation_request, classname: nil)
    link_to "Delete request",
      send("planning_application_#{request_type(validation_request)}_path",
        planning_application, validation_request),
      method: :delete, data: {confirm: "Are you sure?"}, class: classname
  end

  def cancel_request_url(planning_application, validation_request)
    send("cancel_planning_application_#{request_type(validation_request)}_path", planning_application,
      validation_request)
  end

  def edit_validation_request_url(planning_application, validation_request)
    type = request_type(validation_request)

    return if type.eql?("replacement_document_validation_request")

    link_to "Edit", [:edit, planning_application, validation_request]
  end

  def document_url(document)
    link_to(document.name.to_s,
      edit_planning_application_document_path(document.planning_application, document.id))
  end

  def show_validation_request_link(application, request)
    text = application.validated? ? t(".view") : t(".view_and_update")
    url = show_validation_request_url(application, request)
    link_to(text, url)
  end

  def show_validation_request_url(application, request)
    if request.is_a?(AdditionalDocumentValidationRequest)
      show_additional_document_validation_request_url(application, request)
    else
      polymorphic_path([application, request])
    end
  end

  def show_additional_document_validation_request_url(application, request)
    if request.post_validation?
      planning_application_documents_path(application)
    else
      validation_documents_planning_application_path(application)
    end
  end

  def display_request_date_state(validation_request)
    validation_request.days_until_response_due.positive? ? "green" : "red"
  end

  def submit_button_text(planning_application, action_name)
    if action_name.eql?("edit")
      "Update request"
    elsif planning_application.not_started?
      "Save request"
    else
      "Send request"
    end
  end

  def post_validation_requests_index?
    action_name == "post_validation_requests"
  end

  private

  def request_type(validation_request)
    validation_request.class.name.underscore
  end
end
