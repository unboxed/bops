# frozen_string_literal: true

class ReviewPolicyClassLinkComponent < ViewComponent::Base
  def initialize(policy_class:)
    @policy_class = policy_class
  end

  attr_reader :policy_class

  def link_path
    case policy_class.review_status
    when "not_checked_yet"
      edit_planning_application_review_policy_class_path(policy_class.planning_application, policy_class)
    when "complete"
      planning_application_review_policy_class_path(policy_class.planning_application, policy_class)
    end
  end

  def link_text
    "Review assessment of Part #{policy_class.part}, Class #{policy_class.section}"
  end
end
