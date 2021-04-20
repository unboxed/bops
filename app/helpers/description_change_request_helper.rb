module DescriptionChangeRequestHelper
  def display_request_date_state(description_change_request)
    if description_change_request.state == "closed"
      "grey"
    elsif description_change_request.days_until_response_due.positive?
      "green"
    else
      "red"
    end
  end

  def display_request_status(description_change_request)
    if description_change_request.state == "open"
      "grey"
    elsif description_change_request.approved == false
      "red"
    else
      "green"
    end
  end
end
