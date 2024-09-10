# frozen_string_literal: true

class PlanningApplicationPolicyClass < ApplicationRecord
  belongs_to :planning_application
  belongs_to :new_policy_class

  alias_method :policy_class, :new_policy_class
end
