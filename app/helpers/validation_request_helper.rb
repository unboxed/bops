# frozen_string_literal: true

module ValidationRequestHelper
  def edit_request_link(planning_application, validation_request, classname: nil)
    govuk_link_to "Edit request",
      edit_planning_application_validation_validation_request_path(planning_application, validation_request),
      class: classname
  end

  def delete_confirmation_request_link(planning_application, validation_request, classname: nil)
    govuk_link_to "Delete request",
      planning_application_validation_validation_request_path(planning_application, validation_request),
      method: :delete, data: {confirm: "Are you sure?"}, class: classname
  end

  def validation_request_review_header(planning_application)
    if planning_application.has_only_time_extension_requests?
      "Review time extension requests"
    else
      "Review validation requests"
    end
  end

  def show_validation_request_link(application, request)
    text = (!application.validated?) ? t("planning_applications.validation.validation_requests.table.view_and_update") : t("planning_applications.validation.validation_requests.table.view")
    url = show_validation_request_url(application, request)
    govuk_link_to(text, url)
  end

  def show_validation_request_url(application, request)
    if request.type == "AdditionalDocumentValidationRequest"
      show_additional_document_validation_request_url(application, request)
    else
      planning_application_validation_validation_request_path(application, request)
    end
  end

  def show_additional_document_validation_request_url(application, request)
    if request.post_validation?
      planning_application_documents_path(application)
    else
      edit_planning_application_validation_documents_path(application)
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
end
