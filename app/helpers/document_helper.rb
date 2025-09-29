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
    "#{document.name}#{" - #{document.numbers}" if document.numbers?}"
  end

  def document_thumbnail_link(document, thumbnail_args: {}, image_args: {})
    image = if document.representable?
      image_tag(document.representation_url(**thumbnail_args) || "", **image_args)
    else
      image_tag("placeholder/blank_image.png", **image_args.merge(alt: "Blank image"))
    end

    link_to_document image, document
  end

  def document_link_path(document)
    if document.status == :invalid
      planning_application_validation_replacement_document_validation_request_path(
        document.planning_application,
        document.replacement_document_validation_request
      )
    else
      edit_planning_application_document_path(
        document.planning_application,
        document,
        validate: :yes
      )
    end
  end
end
