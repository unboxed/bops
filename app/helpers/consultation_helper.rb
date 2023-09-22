# frozen_string_literal: true

module ConsultationHelper
  def neighbour_letter_content(consultation)
    "# #{consultation.neighbour_letter_header}\n\n#{consultation.neighbour_letter_content.gsub('CURRENT_USER',
                                                                                               current_user.name)}"
  end
end
