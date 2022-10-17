# frozen_string_literal: true

class PastApplicationsErrorPresenter < ErrorPresenter
  private

  def attributes_map
    {
      entry: :application_reference_numbers,
      additional_information: :relevant_information
    }
  end
end
