# frozen_string_literal: true

class ConsultationSummaryErrorPresenter < ErrorPresenter
  private

  def attributes_map
    {entry: :summary_of_consultation_responses}
  end
end
