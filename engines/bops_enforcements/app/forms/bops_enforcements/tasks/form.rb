# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class Form
      include BopsCore::Tasks::Form
      include BopsEnforcements::Engine.routes.url_helpers
      include BopsEnforcements::Engine.routes.mounted_helpers

      def enforcement
        case_record.caseable
      end

      private

      def save_and_complete
        enforcement.start_validation! if enforcement.not_started?
        super
      end
    end
  end
end
