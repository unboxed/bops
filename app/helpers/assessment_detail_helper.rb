# frozen_string_literal: true

module AssessmentDetailHelper
  def neighbour_responses_summary_text(neighbour_responses_by_summary_tag)
    return "There are no neighbour responses" unless neighbour_responses_by_summary_tag.any?

    summary_text = neighbour_responses_by_summary_tag.map do |tag, count|
      "#{count} #{tag}"
    end

    "There is #{summary_text.join(', ')}."
  end
end
