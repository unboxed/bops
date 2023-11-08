# frozen_string_literal: true

module PlanningApplications
  module Assessment
    module PolicyClasses
      class SummaryComponent < ViewComponent::Base
        def initialize(policy_class:)
          @policy_class = PolicyClassPresenter.new(policy_class)
        end

        private

        attr_reader :policy_class

        delegate(
          :section,
          :name,
          :part,
          :planning_application,
          :policies,
          :default_path,
          to: :policy_class
        )

        def policies_summary
          if policies.to_be_determined.any?
            t("planning_applications.assessment.policy_classes.summary_component.to_be_determined")
          elsif policies.does_not_comply.any?
            t("planning_applications.assessment.policy_classes.summary_component.does_not_comply")
          else
            t("planning_applications.assessment.policy_classes.summary_component.complies")
          end
        end
      end
    end
  end
end
