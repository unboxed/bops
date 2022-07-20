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

  def unsaved_changes_data
    {
      controller: "unsaved-changes",
      action: "beforeunload@window->unsaved-changes#handleBeforeUnload submit->unsaved-changes#handleSubmit",
      unsaved_changes_target: "form"
    }
  end

  def home_path
    if controller_path == "public/planning_guides"
      public_planning_guides_path
    else
      root_path
    end
  end
end
