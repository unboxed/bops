# frozen_string_literal: true

module DocumentHelper
  def filter_archived(documents)
    documents.select { |file| file.archived? == true }
  end

  def filter_current(documents)
    documents.select { |file| file.archived? == false }.sort_by(&:created_at)
  end
end
