# frozen_string_literal: true

module PlanningApplications
  module Assessment
    module PolicyClasses
      class SummaryComponent < ViewComponent::Base
        def initialize(policy_class:)
          @policy_class = PolicyClassPresenter.new(policy_class)
        end

        def before_render
          @policies_summary = t(policies_summary_key)
        end

        private

        attr_reader :policy_class, :policies_summary

        delegate(
          :section,
          :name,
          :part,
          :planning_application,
          :policies,
          :default_path,
          to: :policy_class
        )

        def policies_summary_key
          if policies.to_be_determined.any?
            ".to_be_determined"
          elsif policies.does_not_comply.any?
            ".does_not_comply"
          else
            ".complies"
          end
        end
      end
    end
  end
end
