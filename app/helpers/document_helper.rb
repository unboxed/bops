# frozen_string_literal: true

module DocumentHelper
  def filter_archived(documents)
    documents.select { |file| file.archived? == true }
  end

  def filter_current(documents)
    documents.select { |file| file.archived? == false }.sort_by(&:created_at)
  end

  def archive_reason_collection_for_radio_buttons
    Document.archive_reasons.keys.map { |k| [k, I18n.t(k)] }
  end

  def tag_collection_for_checkboxes
    Document::TAGS.map do |tag|
      [
        tag,
        tag.humanize,
      ]
    end
  end
end
