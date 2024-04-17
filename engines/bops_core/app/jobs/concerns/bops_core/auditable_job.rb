# frozen_string_literal: true

module BopsCore
  module AuditableJob
    extend ActiveSupport::Concern
    include Auditable

    module ClassMethods
      def audit(event, payload: {}, **options)
        after_perform(**options) do
          audit(event, payload)
        end
      end
    end
  end
end
