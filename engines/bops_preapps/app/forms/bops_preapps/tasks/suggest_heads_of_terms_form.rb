# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class SuggestHeadsOfTermsForm < Form
      self.task_actions = %w[save_and_complete save_draft]

      attr_reader :heads_of_term, :term

      def initialize(task, params = {})
        super

        @heads_of_term = planning_application.heads_of_term
        @term = @heads_of_term.terms.build
      end
    end
  end
end
