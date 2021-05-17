module ChangeRequestHelper
  def request_state(change_request)
    if change_request.class.name == "DescriptionChangeRequest"
      change_request.approved? ? "Accepted" : "Rejected"
    elsif change_request.class.name == "DocumentChangeRequest"
      "Responded"
    end
  end

  def description_approved_or_rejected(change_request)
    if change_request.class.name == "DescriptionChangeRequest"
      if change_request.approved?
        "Description change has been approved by the applicant"
      elsif change_request.approved == false
        change_request.rejection_reason.to_s
      end
    elsif change_request.class.name == "DocumentChangeRequest"
      if change_request.state == "closed"
        change_request.new_document.name
      end
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
