# frozen_string_literal: true

module ApplicationHelper
  def url_for_document(document)
    if document.published?
      api_v1_planning_application_document_url(document.planning_application, document)
    else
      rails_blob_url(document.file)
    end
  end

  def accessible_time(datetime)
    tag.time(datetime.strftime("%e %B %G at %R%P"), { datetime: datetime.iso8601 })
  end
end
