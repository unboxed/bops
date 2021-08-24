# frozen_string_literal: true

module DocumentHelper
  def filter_archived(documents)
    documents.select { |file| file.archived? == true }
  end

  def filter_current(documents)
    documents.select { |file| file.archived? == false }.sort_by(&:created_at)
  end

  def is_plan_tag(tag)
    Document::PLAN_TAGS.include?(tag)
  end

  def is_evidence_tag(tag)
    Document::EVIDENCE_TAGS.include?(tag)
  end
end
