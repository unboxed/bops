# frozen_string_literal: true

module BopsCore
  class MagicLinkMailer < ApplicationMailer
    def magic_link_mail(resource:, subdomain:, subject: "Your magic link")
      @resource = resource
      @sgid = resource.sgid
      @subdomain = subdomain
      @url = magic_link_url

      mail(
        to: resource.email_address,
        subject:
      )
    end

    private

    attr_reader :resource, :sgid, :subdomain

    def magic_link_url
      case resource
      when Consultee
        bops_consultees.dashboard_url(sgid:, subdomain:)
      else
        main_app.root_url
      end
    end
  end
end
