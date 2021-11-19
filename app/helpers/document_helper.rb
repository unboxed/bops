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

  def created_by(document)
    if document.user.present?
      "This document was manually uploaded by #{document.user.name}"
    elsif document.api_user.present?
      "This document was uploaded by #{document.api_user.name}"
    end
  end
end
