# frozen_string_literal: true

module BopsCore
  module Auditable
    extend ActiveSupport::Concern

    included do
      class_attribute :audit_payload, instance_writer: false, default: -> { {} }
    end

    def audit(event, payload = {}, &)
      event = "#{event}.bops_audit"

      if payload.is_a?(Symbol)
        payload = send(payload)
      elsif payload.is_a?(Proc)
        payload = instance_exec(&payload)
      end

      if audit_payload.is_a?(Symbol)
        payload.merge!(send(audit_payload))
      elsif audit_payload.is_a?(Proc)
        payload.merge!(instance_exec(&audit_payload))
      else
        payload.merge!(audit_payload)
      end

      if block_given?
        ActiveSupport::Notifications.instrument(event, payload, &)
      else
        ActiveSupport::Notifications.instrument(event, payload)
      end
    end
  end
end
