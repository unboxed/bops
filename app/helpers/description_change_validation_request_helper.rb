module DescriptionChangeValidationRequestHelper
  def display_request_date_state(description_change_validation_request)
    if description_change_validation_request.state == "closed"
      "grey"
    elsif description_change_validation_request.days_until_response_due.positive?
      "green"
    else
      "red"
    end
  end

  def change_rejected?(description_change_validation_request)
    description_change_validation_request.state == "closed" && description_change_validation_request.approved == false
  end

  def sequence_description(description_change_validation_request)
    "description##{description_change_validation_request.sequence}"
  end
end
