# frozen_string_literal: true

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
        t(".to_be_determined")
      elsif policies.does_not_comply.any?
        t(".does_not_comply")
      else
        t(".complies")
      end
    end
  end
end
