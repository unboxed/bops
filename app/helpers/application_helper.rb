# frozen_string_literal: true

module ApplicationHelper
  include BopsCore::ApplicationHelper

  attr_reader :back_path

  def back_link(classname: "govuk-button govuk-button--secondary")
    link_to(t("back"), back_path, class: classname)
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
      time: comment.created_at.to_date.to_fs,
      user: user_name
    )
  end

  def consistency_checklist_path(consistency_checklist)
    if consistency_checklist.blank?
      new_planning_application_assessment_consistency_checklist_path
    elsif consistency_checklist.in_assessment?
      edit_planning_application_assessment_consistency_checklist_path
    else
      planning_application_assessment_consistency_checklist_path
    end
  end

  def nav_items
    []
  end
end
