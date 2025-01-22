# frozen_string_literal: true

module BopsCore
  class MagicLinkMailer < ApplicationMailer
    def magic_link_mail(resource:, subdomain:, planning_application:, subject: "Your BOPS magic link")
      @resource = resource
      @sgid = resource.sgid
      @subdomain = subdomain
      @planning_application = planning_application
      @url = magic_link_url

      mail(
        to: resource.email_address,
        subject:
      )
    end

    private

    attr_reader :resource, :sgid, :subdomain, :planning_application

    def magic_link_url
      case resource
      when Consultee
        bops_consultees.planning_application_url(
          reference: planning_application.reference, sgid:, subdomain:
        )
      else
        main_app.root_url
      end
    end
  end
end
