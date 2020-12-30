# frozen_string_literal: true

module DocumentHelper
  def filter_archived(documents)
    documents.select { |plan| plan.archived? == true }
  end

  def filter_current(documents)
    documents.select { |plan| plan.archived? == false }.sort_by(&:created_at)
  end

  def archive_reason_collection_for_radio_buttons
    Document.archive_reasons.keys.map { |k| [k, I18n.t(k)] }
  end

  def tag_collection_for_checkboxes
    Document::TAGS.map do |tag|
      [
        tag,
        tag.humanize
      ]
    end
  end
end
