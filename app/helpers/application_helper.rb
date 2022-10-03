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

  def otp_delivery_method_options
    User.otp_delivery_methods.keys.map do |key|
      OpenStruct.new(id: key, name: t(".#{key}"))
    end
  end

  def policy_comment_label(comment)
    if comment.persisted?
      existing_policy_comment_label(comment)
    else
      t("policy_classes.add_comment")
    end
  end

  def existing_policy_comment_label(comment)
    user_name = comment.user_name

    if comment.edited?
      t(
        "policy_classes.comment_updated_on",
        updated_at: comment.updated_at.strftime("%d %b %Y"),
        user: user_name
      )
    else
      t(
        "policy_classes.comment_added_on",
        created_at: comment.created_at.strftime("%d %b %Y"),
        user: user_name
      )
    end
  end

  def consistency_checklist_path(consistency_checklist)
    if consistency_checklist.blank?
      new_planning_application_consistency_checklist_path
    elsif consistency_checklist.in_assessment?
      edit_planning_application_consistency_checklist_path
    else
      planning_application_consistency_checklist_path
    end
  end
end
