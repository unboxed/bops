# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class SuggestHeadsOfTermsForm < BaseForm
      attr_reader :heads_of_term, :term

      def initialize(task)
        super

        @heads_of_term = @planning_application.heads_of_term
        @term = @heads_of_term.terms.build
      end

      def update(params)
        task.update(status: :completed)
      end

      def permitted_fields(params)
        {} # no params sent: just a submit button
      end
    end
  end
end
