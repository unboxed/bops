# frozen_string_literal: true

module BopsCore
  module Tasks
    module ReviewValidationRequestsForm
      extend ActiveSupport::Concern

      def update(_params)
        true
      end

      def permitted_fields(_params)
        {}
      end
    end
  end
end
