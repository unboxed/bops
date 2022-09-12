# frozen_string_literal: true

class PolicyClassPresenter
  include Presentable

  presents :policy_class

  def initialize(policy_class)
    @policy_class = policy_class
  end

  def previous
    self.class.new(super) if super.present?
  end

  def next
    self.class.new(super) if super.present?
  end

  def default_path
    if complete?
      planning_application_policy_class_path(planning_application, self)
    else
      edit_planning_application_policy_class_path(planning_application, self)
    end
  end

  private

  attr_reader :policy_class
end
