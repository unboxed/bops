# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckRequestedServicesForm < Form
      self.task_actions = %w[save_and_complete edit_form]

      attribute :additional_services, default: -> { [] }

      def update(params)
        super do
          case action
          when "save_and_complete"
            save_and_complete
          when "edit_form"
            task.in_progress!
          else
            raise ArgumentError, "Invalid task action: #{action.inspect}"
          end
        end
      end

      private

      def form_params(params)
        params.fetch(param_key, {}).permit(additional_services: [])
      end

      def save_and_complete
        transaction do
          update_additional_services!
          task.complete!
        end
      end

      def update_additional_services!
        names = additional_services.compact_blank.map(&:to_sym)

        services = names.map do |name|
          planning_application.additional_services.find_or_initialize_by(name: name)
        end

        (planning_application.additional_services = services).map(&:save)
      end
    end
  end
end
