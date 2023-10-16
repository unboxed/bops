# frozen_string_literal: true

module DocumentHelper
  def filter_archived(documents)
    documents.select { |file| file.archived? == true }
  end

  def plan_tag?(tag)
    Document::PLAN_TAGS.include?(tag)
  end

  def evidence_tag?(tag)
    Document::EVIDENCE_TAGS.include?(tag)
  end

  def created_by(document)
    if document.user.present?
      "This document was manually uploaded by #{document.user.name}."
    elsif document.api_user.present?
      "This document was uploaded by the applicant on PlanX."
    end
  end

  def document_name_and_reference(document)
    "#{document.name}#{document.numbers? ? " - #{document.numbers}" : ''}"
  end

  def titled_reference_or_file_name(document)
    document.numbers? ? "Reference: #{document.numbers}" : "File name: #{document.name}"
  end

  def reference_or_file_name(document)
    document.numbers.presence || document.name
  end
end
