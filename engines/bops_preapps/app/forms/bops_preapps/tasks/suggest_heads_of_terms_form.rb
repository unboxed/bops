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
        if params[:button] == "save_draft"
          task.start!
        else
          task.complete!
        end
      rescue ActiveRecord::ActiveRecordError
        false
      end

      def permitted_fields(params)
        params # no params sent: just a submit button
      end
    end
  end
end
