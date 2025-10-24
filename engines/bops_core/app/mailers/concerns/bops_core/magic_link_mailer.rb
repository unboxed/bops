# frozen_string_literal: true

module BopsCore
  class MagicLinkMailer < ApplicationMailer
    def magic_link_mail(resource:, planning_application:, email:, subject: "Your BOPS magic link")
      resource.touch(:magic_link_last_sent_at)

      @resource = resource
      @sgid = resource.sgid
      @planning_application = planning_application
      @subdomain = planning_application.local_authority.subdomain
      @url = magic_link_url
      @email = email

      view_mail(
        NOTIFY_TEMPLATE_ID,
        to: email,
        subject:,
        reply_to_id: planning_application.local_authority.shared_email_reply_to_id
      )
    end

    private

    attr_reader :resource, :sgid, :subdomain, :planning_application, :email

    def magic_link_url
      case resource
      when Consultee
        bops_consultees.planning_application_url(
          reference: planning_application.reference, sgid:, subdomain:
        )
      when PlanningApplication
        bops_reports.planning_application_url(
          reference: planning_application.reference, sgid:, subdomain:
        )
      else
        main_app.root_url
      end
    end
  end
end
