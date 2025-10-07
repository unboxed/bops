# frozen_string_literal: true

require "notifications/client"

module BopsCore
  module MagicLink
    class ExpiredMagicLinkForm
      include ActiveModel::Model
      include ActiveModel::Attributes

      attr_accessor :email, :consultee

      validates :email, presence: true
      validate :email_domain_matches_consultee

      def email_domain_matches_consultee
        submitted_domain = email.split("@").last
        consultee_domain = consultee.email_address.split("@").last

        if submitted_domain != consultee_domain
          errors.add(:email, "Email must be a [#{consultee_domain}] address.")
        end
      end
    end
  end
end
