# frozen_string_literal: true

module BopsCore
  module AuditableMailer
    extend ActiveSupport::Concern
    include Auditable

    module ClassMethods
      def audit(*actions, event: nil, payload: {}, **options)
        after_deliver(only: actions, **options) do
          default_event = [mailer_name, action_name].join(".")
          audit(event || default_event, payload)
        end
      end
    end
  end
end
