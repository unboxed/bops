# frozen_string_literal: true

class PlanningApplicationMailer < ApplicationMailer
  helper :planning_application

  def decision_notice_mail(planning_application, host, user)
    @planning_application = planning_application
    @host = host

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:decision_notice_mail, application_type_name: @planning_application.application_type.human_name),
      to: user
    )
  end

  def validation_notice_mail(planning_application, email)
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:validation_notice_mail,
                       application_type_name: @planning_application.application_type.human_name),
      to: email,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def invalidation_notice_mail(planning_application)
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:invalidation_notice_mail,
                       application_type_name: @planning_application.application_type.human_name),
      to: @planning_application.applicant_and_agent_email.first,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def receipt_notice_mail(planning_application, email)
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:receipt_notice_mail, application_type_name: @planning_application.application_type.human_name),
      to: email,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def validation_request_mail(planning_application)
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:validation_request_mail,
                       application_type_name: @planning_application.application_type.human_name),
      to: @planning_application.applicant_and_agent_email.first,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def post_validation_request_mail(planning_application, validation_request)
    @planning_application = planning_application
    @validation_request = validation_request

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:post_validation_request_mail,
                       application_type_name: @planning_application.application_type.human_name),
      to: @planning_application.applicant_and_agent_email.first,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def cancelled_validation_request_mail(planning_application)
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:cancelled_validation_request_mail,
                       application_type_name: @planning_application.application_type.human_name),
      to: @planning_application.applicant_and_agent_email.first,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def description_change_mail(planning_application, description_change_request)
    @planning_application = planning_application
    @description_change_request = description_change_request

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:description_change_mail,
                       application_type_name: @planning_application.application_type.human_name),
      to: @planning_application.applicant_and_agent_email.first,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def description_closure_notification_mail(planning_application, description_change_request)
    @planning_application = planning_application
    @description_change_request = description_change_request

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:description_closure_notification_mail,
                       application_type_name: @planning_application.application_type.human_name),
      to: @planning_application.applicant_and_agent_email.first,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def validation_request_closure_mail(planning_application)
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:validation_request_closure_mail,
                       application_type_name: @planning_application.application_type.human_name),
      to: @planning_application.applicant_and_agent_email.first,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def neighbour_consultation_letter_copy_mail(planning_application, email)
    @planning_application = planning_application
    @consultation = planning_application.consultation

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:neighbour_consultation_letter_copy_mail),
      to: email,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def neighbour_site_notice_copy
    @planning_application = planning_application
    @site_notice = @planning_application.site_notices.last

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:neighbour_site_notice_copy),
      to: email,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end
end
