# frozen_string_literal: true

module BopsCore
  class MagicLinkMailerJob < ApplicationJob
    queue_as :low_priority

    def perform(resource:, planning_application:, subdomain:)
      MagicLinkMailer.magic_link_mail(
        resource: resource,
        planning_application: planning_application,
        subdomain: subdomain
      ).deliver_now
    end
  end
end
