# frozen_string_literal: true

class PolicySectionForm
  include ActiveModel::Model

  attr_reader :planning_application, :policy_class, :planning_application_policy_sections

  def initialize(planning_application:, policy_class:)
    @planning_application = planning_application
    @policy_class = policy_class
  end

  def update(params)
    params.each do |policy_section_id, section_params|
      planning_application_policy_section = PlanningApplicationPolicySection.find_by(planning_application: @planning_application.presented, policy_section_id:)

      update_attributes = {
        status: section_params[:status],
        comments_attributes: section_params[:comments_attributes]
      }.compact

      planning_application_policy_section.update!(update_attributes)
    end
  end
end
