# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckAndAddRequirementsForm < BaseForm
      def update(params)
        task.update!(status: :completed)
      rescue ActiveRecord::RecordInvalid
        false
      end

      def permitted_fields(params)
        {} # no params sent: just a submit button
      end
    end
  end
end
