# frozen_string_literal: true

module ApplicationHelper
  attr_reader :back_path

  def back_link(classname: "govuk-button govuk-button--secondary")
    link_to(t("back"), back_path, class: classname)
  end

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
    User.otp_delivery_methods.keys.map { |key| [key, t(".#{key}")] }
  end

  def policy_comment_label(comment)
    if comment.present?
      existing_policy_comment_label(comment)
    else
      t("policy_classes.add_comment")
    end
  end

  def existing_policy_comment_label(comment)
    user_name = comment.user_name
    action = comment.first? ? :added : :updated

    t(
      "policy_classes.comment_#{action}_on",
      time: comment.created_at.strftime("%d %b %Y"),
      user: user_name
    )
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

  def assessment_detail_error_presenter(category)
    if %w[past_applications consultation_summary].include?(category)
      "#{category.camelize}ErrorPresenter".constantize
    else
      ErrorPresenter
    end
  end

  def assessment_detail_fields_partial_path(category)
    if %w[past_applications consultation_summary].include?(category)
      "planning_application/assessment_details/#{category}"
    else
      "planning_application/assessment_details"
    end
  end

  def new_assessment_detail_title(category:, update:)
    action = update ? :update : :new
    t("assessment_details.#{action}_#{category}")
  end
end
