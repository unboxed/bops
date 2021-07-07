module ValidationRequestHelper
  def request_state(validation_request)
    if validation_request.instance_of?(DescriptionChangeValidationRequest)
      validation_request.approved? ? "Accepted" : "Rejected"
    else
      "Responded"
    end
  end

  def applicant_response(validation_request)
    if validation_request.instance_of?(DescriptionChangeValidationRequest) || validation_request.instance_of?(RedLineBoundaryChangeValidationRequest)
      if validation_request.approved?
        approval_message(validation_request)
      elsif validation_request.approved == false
        validation_request.rejection_reason.to_s
      end
    elsif validation_request.class.name.include?("Other") && validation_request.state == "closed"
      link_to("View response", planning_application_other_change_validation_request_path(validation_request.planning_application, validation_request))
    elsif validation_request.state == "closed"
      link_to(validation_request.new_document.name.to_s, edit_planning_application_document_path(validation_request.planning_application, validation_request.new_document.id.to_s))
    end
  end

  def approval_message(validation_request)
    if validation_request.instance_of?(DescriptionChangeValidationRequest)
      "Description change has been approved by the applicant"
    elsif validation_request.instance_of?(RedLineBoundaryChangeValidationRequest)
      "Change to red line boundary has been approved by the applicant"
    end
  end

  def display_request_status(validation_request)
    if validation_request.state == "closed"
      "grey"
    elsif validation_request.overdue?
      "red"
    else
      "green"
    end
  end

  def overdue_requests(validation_requests)
    validation_requests.select { |req| req.overdue? && req.state == "open" }
  end
end
