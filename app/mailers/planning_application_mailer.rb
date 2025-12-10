# frozen_string_literal: true

class PlanningApplicationMailer < ApplicationMailer
  helper :planning_application
  helper :mailer

  def decision_notice_mail(planning_application, host, email)
    @planning_application = planning_application
    @decision_notice_url = decision_notice_api_v1_planning_application_url(@planning_application, id: @planning_application.reference, format: "pdf", host: host)
    application_type_name = @planning_application.application_type.human_name

    view_mail(email_template_id, headers_for(subject(:decision_notice_mail, application_type_name: application_type_name), email))
  end

  def validation_notice_mail(planning_application, email)
    @planning_application = planning_application
    application_type_name = @planning_application.application_type.human_name

    view_mail(email_template_id, headers_for(subject(:validation_notice_mail, application_type_name: application_type_name), email))
  end

  def invalidation_notice_mail(planning_application)
    @planning_application = planning_application
    application_type_name = @planning_application.application_type.human_name
    email = @planning_application.applicant_and_agent_email.first

    view_mail(email_template_id, headers_for(subject(:invalidation_notice_mail, application_type_name: application_type_name), email))
  end

  def receipt_notice_mail(planning_application, email)
    @planning_application = planning_application
    application_type_name = @planning_application.application_type.human_name

    view_mail(email_template_id, headers_for(subject(:receipt_notice_mail, application_type_name: application_type_name), email))
  end

  def validation_request_mail(planning_application)
    @planning_application = planning_application
    application_type_name = @planning_application.application_type.human_name
    email = @planning_application.applicant_and_agent_email.first

    view_mail(email_template_id, headers_for(subject(:validation_request_mail, application_type_name: application_type_name), email))
  end

  def post_validation_request_mail(planning_application, validation_request)
    @planning_application = planning_application
    @validation_request = validation_request
    application_type_name = @planning_application.application_type.human_name
    email = @planning_application.applicant_and_agent_email.first

    view_mail(email_template_id, headers_for(subject(:post_validation_request_mail, application_type_name: application_type_name), email))
  end

  def pre_commencement_condition_request_mail(planning_application, validation_request)
    @planning_application = planning_application
    @validation_request = validation_request
    application_type_name = @planning_application.application_type.human_name
    email = @planning_application.applicant_and_agent_email.first

    view_mail(email_template_id, headers_for(subject(:pre_commencement_condition_notification, application_type_name: application_type_name), email))
  end

  def cancelled_validation_request_mail(planning_application)
    @planning_application = planning_application
    application_type_name = @planning_application.application_type.human_name
    email = @planning_application.applicant_and_agent_email.first

    view_mail(email_template_id, headers_for(subject(:cancelled_validation_request_mail, application_type_name: application_type_name), email))
  end

  def description_change_mail(planning_application, description_change_request)
    @planning_application = planning_application
    @description_change_request = description_change_request
    application_type_name = @planning_application.application_type.human_name
    email = @planning_application.applicant_and_agent_email.first

    view_mail(email_template_id, headers_for(subject(:description_change_mail, application_type_name: application_type_name), email))
  end

  def description_update_mail(planning_application, description_change_request)
    @planning_application = planning_application
    @description_change_request = description_change_request
    application_type_name = @planning_application.application_type.human_name
    email = @planning_application.applicant_and_agent_email.first

    view_mail(email_template_id, headers_for(subject(:description_update_mail, application_type_name: application_type_name), email))
  end

  def description_closure_notification_mail(planning_application, description_change_request)
    @planning_application = planning_application
    @description_change_request = description_change_request
    application_type_name = @planning_application.application_type.human_name
    email = @planning_application.applicant_and_agent_email.first

    view_mail(email_template_id, headers_for(subject(:description_closure_notification_mail, application_type_name: application_type_name), email))
  end

  def pre_commencement_condition_closure_notification_mail(planning_application, change_request)
    @planning_application = planning_application
    @change_request = change_request
    application_type_name = @planning_application.application_type.human_name
    email = @planning_application.applicant_and_agent_email.first

    view_mail(email_template_id, headers_for(subject(:pre_commencement_condition_closure_notification_mail, application_type_name: application_type_name), email))
  end

  def validation_request_closure_mail(planning_application)
    @planning_application = planning_application
    application_type_name = @planning_application.application_type.human_name
    email = @planning_application.applicant_and_agent_email.first

    view_mail(email_template_id, headers_for(subject(:validation_request_closure_mail, application_type_name: application_type_name), email))
  end

  def neighbour_consultation_letter_copy_mail(planning_application, email)
    @planning_application = planning_application
    @consultation = planning_application.consultation

    view_mail(email_template_id, headers_for(subject(:neighbour_consultation_letter_copy_mail), email))
  end

  def site_notice_mail(planning_application, email)
    @planning_application = planning_application
    @site_notice = @planning_application.site_notices.last
    reference = @planning_application.reference

    view_mail(email_template_id, headers_for(subject(:site_notice_mail, reference: reference), email))
  end

  def site_notice_confirmation_request_mail(site_notice, user)
    @planning_application = site_notice.planning_application
    @local_authority = @planning_application.local_authority
    @site_notice = site_notice
    @user = user
    reference = @planning_application.reference
    email = @site_notice.internal_team_email

    view_mail(email_template_id, headers_for(subject(:site_notice_confirmation_request_mail, reference: reference), email))
  end

  def internal_team_site_notice_mail(planning_application, email)
    @planning_application = planning_application
    @site_notice = @planning_application.site_notices.last
    reference = @planning_application.reference

    view_mail(email_template_id, headers_for(subject(:internal_team_site_notice_mail, reference: reference), email))
  end

  def press_notice_mail(press_notice)
    @press_notice = press_notice
    @planning_application = press_notice.planning_application
    email = press_notice.press_notice_email

    view_mail(email_template_id, headers_for(subject(:press_notice_mail), email))
  end

  def press_notice_confirmation_request_mail(press_notice, user)
    @planning_application = press_notice.planning_application
    @local_authority = @planning_application.local_authority
    @press_notice = press_notice
    @user = user
    reference = @planning_application.reference
    email = @press_notice.press_notice_email

    view_mail(email_template_id, headers_for(subject(:press_notice_confirmation_request_mail, reference: reference), email))
  end

  def send_committee_decision_mail(planning_application, user)
    @planning_application = planning_application
    @user = user
    email = @planning_application.applicant_and_agent_email.first

    view_mail(email_template_id, headers_for(subject(:committee_decision_mail), email))
  end

  def report_mail(planning_application, email)
    @planning_application = planning_application
    council_name = @planning_application.local_authority.council_name

    view_mail(email_template_id, headers_for(subject(:report_mail, council_name: council_name), email))
  end

  private

  attr_reader :planning_application
  delegate :local_authority, to: :planning_application

  with_options to: :local_authority, allow_nil: true do
    delegate :notify_api_key, :email_template_id, :email_reply_to_id
  end

  def headers_for(subject, email)
    {
      to: email,
      subject: subject,
      reply_to_id: email_reply_to_id,
      delivery_method: :notify,
      delivery_method_options: {
        api_key: notify_api_key
      }
    }
  end
end
