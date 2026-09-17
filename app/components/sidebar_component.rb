# frozen_string_literal: true

class SidebarComponent < ViewComponent::Base
  include Rails.application.routes.url_helpers
  include Rails.application.routes.mounted_helpers

  def initialize(params: {}, case_record: nil, task: nil)
    @params = params
    @case_record = case_record
    @task = task
  end

  private

  attr_reader :params, :case_record

  def tasks
    if @task.blank? || (TrueClass === @task)
      case_record.tasks
    else
      [@task]
    end
  end

  def section
    @task&.section
  end

  def render_task(task, top_level: false)
    if task.section.present?
      render_section(task, top_level:)
    else
      is_active = current_task?(task)
      link_options = is_active ? {"aria-current": "page"} : {}
      link = helpers.govuk_link_to(task.name, task.url, **link_options)
      content = safe_join([status_indicator_for(task), link], " ")
      li_classes = class_names("bops-sidebar__task", {"bops-sidebar__task--active": is_active})

      helpers.tag.li(content, class: li_classes)
    end
  end

  def render_section(section, top_level: false)
    visible_tasks = section.tasks.visible
    return if visible_tasks.empty?

    elements = []

    elements << helpers.tag.li(class: "bops-sidebar__heading") { helpers.tag.h3("#{section.section} tasks") } unless top_level

    tasks = visible_tasks.map { |task| render_task(task) }

    elements << helpers.tag.li(safe_join(tasks))

    safe_join(elements)
  end

  def local_authority
    @local_authority ||= request.env["bops.local_authority"]
  end

  def planning_application_reference
    params[:reference] || params[:planning_application_reference]
  end

  def planning_application
    return unless case_record&.caseable_type == "PlanningApplication"

    @planning_application ||= local_authority.planning_applications.find_by!(reference: planning_application_reference)
  end

  def status_indicator_for(task)
    return if task.status_hidden?

    icon_markup = helpers.render("shared/icons/#{task.status}")
    helpers.content_tag(:span, icon_markup, class: "bops-sidebar__task-icon", aria: {hidden: true})
  end

  def current_task?(task)
    current_slug = params[:slug]
    return false if current_slug.blank?

    task.full_slug == current_slug
  end

  def section_task(section)
    @planning_application.case_record.tasks.find_by(section:)&.first_child
  end
end
