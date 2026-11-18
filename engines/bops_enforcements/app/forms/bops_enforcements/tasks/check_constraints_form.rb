# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class CheckConstraintsForm < Form
      self.task_actions = %w[add_constraint remove_constraint save_draft save_and_complete edit_form]

      attribute :constraint_id, :integer

      after_initialize do
        @constraints = enforcement.constraints
        @case_constraints = enforcement.case_constraints
      end
      attr_reader :constraints, :case_constraints
      # delegate :constraints, :case_constraints, to: enforcement

      def other_constraints(query: "")
        scope = Constraint.options_for_local_authority(case_record.local_authority_id).order(:category)

        if query.present?
          scope = scope.where(search_query, search_param(query))
        end

        scope.non_applicable_constraints(case_constraints).sort_by(&:category)
      end

      private

      def save_and_complete
        super do
        end
      end

      def add_constraint
        case_constraints.create!(constraint_id:, identified_by: Current.user.name) && task.start!
      end

      def remove_constraint
        constraint = case_constraints.find(constraint_id)
        constraint.destroy! && task.start!
      end

      def non_applicable_constraints(applicable_constraints)
        Constraint.all.where.not(id: applicable_constraints.pluck(:constraint_id))
      end

      def search_query
        "#{Constraint.quoted_table_name}.#{Constraint.quote_column_name("search")} @@ to_tsquery('simple', ?)"
      end

      def search_param(query)
        query.to_s
          .scan(/[-\w]{3,}/)
          .map { |word| word.gsub(/^-/, "!") }
          .map { |word| word.gsub(/-$/, "") }
          .map { |word| word.gsub(/.+/, "\\0:*") }
          .join(" & ")
      end
    end
  end
end
