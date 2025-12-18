# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class OtherValidationRequestsForm < Form
      class ValidationRequestDecorator < SimpleDelegator
        def created_by
          user&.name
        end

        def status
          case state
          when "closed"
            :updated
          when "cancelled"
            :cancelled
          else
            :invalid
          end
        end
      end

      self.task_actions = %w[save_draft save_and_complete]

      def update(params)
        super do
          case action
          when "save_draft"
            task.start!
          when "save_and_complete"
            task.complete!
          else
            raise ArgumentError, "Invalid task action: #{action.inspect}"
          end
        end
      end

      def validation_requests
        @validation_requests ||= validation_requests_relation.load
      end

      def each_validation_request
        validation_requests.each do |validation_request|
          yield ValidationRequestDecorator.new(validation_request)
        end
      end

      private

      def validation_requests_relation
        planning_application.other_change_validation_requests.includes(:user).by_created_at
      end
    end
  end
end
