# frozen_string_literal: true

module DescriptionChangeValidationRequestHelper
  def change_rejected?(description_change_validation_request)
    description_change_validation_request.closed? && description_change_validation_request.approved == false
  end

  def sequence_description(description_change_validation_request)
    "description##{description_change_validation_request.sequence}"
  end

  def format_datetime(datetime_str)
    datetime = DateTime.parse(datetime_str)
    datetime.strftime("%-d %B %Y")
  end
end
