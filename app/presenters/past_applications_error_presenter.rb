# frozen_string_literal: true

class PastApplicationsErrorPresenter < ErrorPresenter
  private

  def formatted_message(message, attribute)
    attribute = attributes_map[attribute] || attribute
    super(message, attribute)
  end

  def attributes_map
    {
      entry: :application_reference_numbers,
      additional_information: :relevant_information
    }
  end
end
