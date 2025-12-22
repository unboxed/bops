# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class ReviewValidationRequestsForm < Form
      def update(_params)
        true
      end

      def permitted_fields(_params)
        {}
      end
    end
  end
end
