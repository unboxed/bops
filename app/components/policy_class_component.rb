# frozen_string_literal: true

class PolicyClassComponent < ViewComponent::Base
  def initialize(policy_class:)
    @policy_class = policy_class
  end

  private

  attr_reader :policy_class

  delegate(
    :section,
    :name,
    :part,
    :planning_application,
    :policies,
    :complete?,
    to: :policy_class
  )

  def path
    if complete?
      planning_application_policy_class_path(planning_application, policy_class)
    else
      edit_planning_application_policy_class_path(
        planning_application,
        policy_class
      )
    end
  end

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
