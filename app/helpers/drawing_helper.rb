# frozen_string_literal: true

module DrawingHelper
  def filter_archived(drawings)
    drawings.select { |plan| plan.archived? == true }
  end

  def filter_current(drawings)
    drawings.select { |plan| plan.archived? == false }.sort_by(&:archived_at)
  end

  def archive_reason_collection_for_radio_buttons
    Drawing.archive_reasons.keys.map { |k| [k, I18n.t(k)] }
  end

  def tag_collection_for_checkboxes
    Drawing::TAGS.map do |tag|
      [
        tag,
        tag.humanize
      ]
    end
  end
end
