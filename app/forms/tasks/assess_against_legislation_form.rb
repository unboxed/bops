# frozen_string_literal: true

module Tasks
  class AssessAgainstLegislationForm < Form
    self.task_actions = %w[default save_draft save_and_complete add_part add_classes add_assessment_area update_assessment]

    attribute :part, :integer
    attribute :classes, :array, type: :integer, default: -> { [] }
    attribute :sections

    with_options on: :add_classes do
      validates :part, presence: {message: "Select a part number from GPDO Schedule 2"}
      validates :part, inclusion: {in: :policy_part_numbers, message: "GPDO Schedule 2 part number is not recognised"}
    end

    with_options on: :add_assessment_area do
      validates :classes, presence: {message: "Select classes from GPDO Schedule 2"}
    end

    delegate :policy_classes, to: :policy_part
    delegate :planning_application_policy_classes, to: :planning_application
    delegate :planning_application_policy_sections, to: :planning_application

    def policy_parts
      @policy_parts ||= PolicySchedule.schedule_2.policy_parts
    end

    def policy_part
      @policy_part ||= policy_parts.find_by_number(part)
    end

    def policy_classes_menu
      @policy_classes_menu ||= policy_classes.menu
    end

    def assessment_area
      @assessment_area ||= planning_application_policy_classes.find(params[:id])
    end

    def assessment_areas
      @assessment_areas ||= planning_application_policy_classes
    end

    def assessment_area_ids
      @assessment_area_ids ||= assessment_areas.pluck(:policy_class_id)
    end

    def assessment_area_name(area = assessment_area)
      policy_class = area.policy_class
      policy_part = policy_class.policy_part

      "Part #{policy_part.number}, Class #{policy_class.section}"
    end

    def assessment_area_description(area = assessment_area)
      area.policy_class.name.upcase_first
    end

    def assessment_area_legislation_url(area = assessment_area)
      area.policy_class.url
    end

    def assessment_area_sections(area = assessment_area)
      section_ids = area.policy_class.policy_section_ids
      planning_application_policy_sections.select { |section| section_ids.include?(section.policy_section_id) }
    end

    def policy_reference(section, area: assessment_area)
      "#{area.policy_class.section}.#{section.section}"
    end

    def complies?(area)
      assessment_area_sections(area).all?(&:complies?)
    end

    def does_not_comply?(area)
      assessment_area_sections(area).any?(&:does_not_comply?)
    end

    def assessment_area_url(area = assessment_area)
      route_for(:task_component, planning_application, slug: task.full_slug, id: area.id, only_path: true)
    end

    def edit_assessment_area_url(area)
      route_for(:edit_task_component, planning_application, slug: task.full_slug, id: area.id, only_path: true)
    end

    def remove_assessment_area_url(area)
      route_for(:planning_application_assessment_policy_areas_policy_class, planning_application, area, redirect_to: url, only_path: true)
    end

    def after_success
      case action
      when "add_assessment_area", "save_draft", "save_and_complete"
        "redirect"
      when "remove_assessment_area", "update_assessment"
        "redirect"
      else
        "render"
      end
    end

    def after_failure
      case action
      when "remove_assessment_area"
        "redirect"
      else
        "render"
      end
    end

    private

    def permitted_attributes
      case action
      when "add_part"
        [:part]
      when "add_classes", "add_assessment_area"
        [:part, classes: []]
      when "update_assessment"
        [sections: [:id, :status, comments_attributes: [:text]]]
      else
        []
      end
    end

    def form_params(params)
      params.fetch(param_key, {}).permit(*permitted_attributes)
    end

    def default
      true
    end

    def add_part
      true
    end

    def add_classes
      true
    end

    def add_assessment_area
      policy_classes.where(id: classes).find_each do |policy_class|
        assessment_areas.create_or_find_by!(policy_class_id: policy_class.id)
      end

      true
    rescue ActiveRecord::ActiveRecordError
      false
    end

    def update_assessment
      planning_application_policy_sections.update!(sections.keys, sections.values)

      true
    rescue ActiveRecord::ActiveRecordError
      false
    end

    def policy_part_numbers
      policy_parts.map(&:number)
    end
  end
end
