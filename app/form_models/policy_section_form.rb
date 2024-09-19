# frozen_string_literal: true

class PolicySectionForm
  include ActiveModel::Model

  attr_reader :planning_application, :policy_class, :planning_application_policy_sections

  def initialize(planning_application:, policy_class:)
    @planning_application = planning_application
    @policy_class = policy_class
    @planning_application_policy_sections = build_planning_application_policy_sections
  end

  def build_planning_application_policy_sections
    policy_class.policy_sections.map do |policy_section|
      PlanningApplicationPolicySection.find_or_initialize_by(
        planning_application: @planning_application.presented,
        policy_section: policy_section
      )
    end.index_by(&:policy_section_id)
  end

  def update(params)
    params.each do |policy_section_id, section_params|
      planning_application_policy_section = planning_application_policy_sections[policy_section_id.to_i]
      planning_application_policy_section.update!(
        status: section_params[:status],
        comments_attributes: section_params[:comments_attributes]
      )
    end
  end
end
