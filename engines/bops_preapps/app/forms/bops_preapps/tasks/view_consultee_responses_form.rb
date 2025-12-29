# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class ViewConsulteeResponsesForm < Form
      self.task_actions = %w[save_draft save_and_complete]

      delegate :consultation, to: :planning_application

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

      def consultees
        @consultees ||= consultation&.consultees&.sorted || []
      end

      def response_summary
        @response_summary ||= calculate_response_summary
      end

      private

      def calculate_response_summary
        counts = {total: 0, responded: 0, awaiting: 0, not_consulted: 0}

        consultees.each do |consultee|
          counts[:total] += 1
          if consultee.responses?
            counts[:responded] += 1
          elsif consultee.awaiting_response?
            counts[:awaiting] += 1
          elsif consultee.not_consulted?
            counts[:not_consulted] += 1
          end
        end

        counts
      end
    end
  end
end
