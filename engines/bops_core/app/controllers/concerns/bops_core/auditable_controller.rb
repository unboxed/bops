# frozen_string_literal: true

module BopsCore
  module AuditableController
    extend ActiveSupport::Concern
    include Auditable

    AUDITABLE_ACTIONS = {}.tap do |actions|
      actions.merge!(
        "create" => "created",
        "update" => "updated",
        "destroy" => "destroyed"
      )

      actions.default_proc = ->(_, key) { key }
    end.freeze

    module ClassMethods
      def audit(*actions, event: nil, payload: {}, **options)
        after_action(only: actions, **options) do
          default_event = [
            AUDITABLE_ACTIONS[action_name],
            controller_name.singularize
          ].join(".")

          audit(event || default_event, payload)
        end
      end
    end
  end
end
