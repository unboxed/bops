# frozen_string_literal: true

module AssessmentDetailHelper
  def neighbour_responses_summary_text(neighbour_responses_by_summary_tag)
    return "There are no neighbour responses" unless neighbour_responses_by_summary_tag.any?

    summary_text = neighbour_responses_by_summary_tag.map.with_index do |(tag, count), i|
      i.zero? ? t(:neighbour_responses_by_summary_tag, tag:, count:) : "#{count} #{tag}"
    end

    "#{summary_text.join(", ")}."
  end

  def updated_neighbour_responses_summary_text(responses, detail)
    count = if detail.created_at.nil?
      responses.length
    else
      responses.where("neighbour_responses.created_at > ?", detail.updated_at).length
    end

    t(:neighbour_responses_by_summary_tag, tag: "new neighbour response", count:)
  end
end
