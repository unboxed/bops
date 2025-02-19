# frozen_string_literal: true

module DocumentHelper
  def filter_archived(documents)
    documents.select { |file| file.archived? == true }
  end

  def drawing_tag?(tag)
    Document::DRAWING_TAGS.include?(tag)
  end

  def evidence_tag?(tag)
    Document::EVIDENCE_TAGS.include?(tag)
  end

  def supporting_document_tag?(tag)
    Document::SUPPORTING_DOCUMENT_TAGS.include?(tag)
  end

  def created_by(document)
    if document.user.present?
      "This document was manually uploaded by #{document.user.name}."
    elsif document.api_user.present?
      "This document was uploaded by the applicant on PlanX."
    end
  end

  def document_name_and_reference(document)
    "#{document.name}#{document.numbers? ? " - #{document.numbers}" : ""}"
  end

  def reference_or_file_name(document)
    document.numbers.presence || document.name
  end

  def link_to_document(link_text, document, **args)
    new_tab = /(new (window|tab)|<img\b)/.match?(link_text) ? "" : true

    govuk_link_to(
      link_text,
      url_for_document(document),
      new_tab:,
      **args
    )
  end

  def url_for_document(document)
    if document.published?
      api_v1_planning_application_document_url(document.planning_application, document)
    else
      uploaded_file_url(document.blob)
    end
  end

  def document_thumbnail_link(document, thumbnail_args: {}, image_args: {})
    image = if document.representable?
      image_tag(document.representation(**thumbnail_args) || "", **image_args)
    else
      image_tag("placeholder/blank_image.png", **image_args.merge(alt: "Blank image"))
    end

    link_to_document image, document
  end
end
