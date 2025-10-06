# frozen_string_literal: true

module BopsCore
  class MagicLinkMailer < ApplicationMailer
    def magic_link_mail(resource:, planning_application:, subject: "Your BOPS magic link")
      resource.touch(:magic_link_last_sent_at)

      @resource = resource
      @sgid = resource.sgid
      @planning_application = planning_application
      @subdomain = planning_application.local_authority.subdomain
      @url = magic_link_url

      view_mail(
        email_template_id,
        to: resource.email_address,
        subject:,
        reply_to_id: email_reply_to_id,
        delivery_method_options: {
          api_key: notify_api_key
        }
      )
    end

    private

    attr_reader :resource, :sgid, :subdomain, :planning_application
    delegate :local_authority, to: :planning_application

    with_options to: :local_authority, allow_nil: true do
      delegate :notify_api_key, :email_template_id, :email_reply_to_id
    end

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
