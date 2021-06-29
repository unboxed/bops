module ChangeRequestHelper
  def request_state(change_request)
    if change_request.instance_of?(DescriptionChangeValidationRequest)
      change_request.approved? ? "Accepted" : "Rejected"
    else
      "Responded"
    end
  end

  def applicant_response(change_request)
    if change_request.instance_of?(DescriptionChangeValidationRequest) || change_request.instance_of?(RedLineBoundaryChangeRequest)
      if change_request.approved?
        approval_message(change_request)
      elsif change_request.approved == false
        change_request.rejection_reason.to_s
      end
    elsif change_request.state == "closed"
      link_to(change_request.new_document.name.to_s, edit_planning_application_document_path(change_request.planning_application, change_request.new_document.id.to_s))
    end
  end

  def approval_message(change_request)
    if change_request.instance_of?(DescriptionChangeValidationRequest)
      "Description change has been approved by the applicant"
    elsif change_request.instance_of?(RedLineBoundaryChangeRequest)
      "Change to red line boundary has been approved by the applicant"
    end
  end

  def display_request_status(change_request)
    if change_request.state == "closed"
      "grey"
    elsif change_request.overdue?
      "red"
    else
      "green"
    end
  end
end
