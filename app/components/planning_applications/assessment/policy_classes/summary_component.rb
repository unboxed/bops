# frozen_string_literal: true

module PlanningApplications
  module Assessment
    module PolicyClasses
      class SummaryComponent < ViewComponent::Base
        def initialize(policy_class:)
          @policy_class = PolicyClassPresenter.new(policy_class)
        end

        def before_render
          @policies_summary = I18n.t(policies_summary_key)
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
            "planning_applications.assessment.policy_classes.summary_component.to_be_determined"
          elsif policies.does_not_comply.any?
            "planning_applications.assessment.policy_classes.summary_component.does_not_comply"
          else
            "planning_applications.assessment.policy_classes.summary_component.complies"
          end
        end
      end
    end
  end
end
