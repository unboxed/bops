# frozen_string_literal: true

class SidebarComponent < ViewComponent::Base
  include Rails.application.routes.url_helpers
  include Rails.application.routes.mounted_helpers

  def initialize(params: {}, task: nil)
    @params = params
    @task = task
  end

  private

  attr_reader :params
  delegate :case_record, to: :planning_application

  def tasks
    if @task.blank? || (TrueClass === @task)
      case_record.tasks
    else
      [@task]
    end
  end

  def render_task(task)
    if task.section.present?
      render_section(task)
    else
      is_active = current_task?(task)
      target = if task.legacy_url.present?
        route_for(task.legacy_url, planning_application)
      else
        BopsPreapps::Engine.routes.url_helpers.task_path(@case_record,
          slug: task.full_slug, reference: planning_application_reference)
      end
      link_options = is_active ? {"aria-current" => "page"} : {}
      link = helpers.govuk_link_to(task.name, target, **link_options)
      content = if task.status_hidden?
        safe_join([invisible_status_placeholder, link], " ")
      else
        safe_join([status_indicator_for(task), link], " ")
      end
      li_classes = ["bops-sidebar__task"]
      li_classes << "bops-sidebar__task--active" if is_active
      helpers.tag.li(content, class: li_classes.join(" "))
    end
  end

  def render_section(section)
    visible_tasks = section.tasks.reject(&:hidden?)
    return if visible_tasks.empty?

    elements = []
    elements << helpers.tag.h3(section.section, class: "govuk-heading-s")
    tasks = visible_tasks.map { |task| render_task(task) }
    elements << helpers.tag.ul(safe_join(tasks), class: "govuk-list govuk-list--spaced")

    safe_join(elements)
  end

  def local_authority
    @local_authority ||= request.env["bops.local_authority"]
  end

  def planning_application_reference
    params[:reference] || params[:planning_application_reference]
  end

  def planning_application
    @planning_application ||= local_authority.planning_applications.find_by!(reference: planning_application_reference)
  end

  def status_indicator_for(task)
    icon_markup = helpers.render("shared/icons/#{task.status}")
    helpers.content_tag(:span, icon_markup, class: "bops-sidebar__task-icon", aria: {hidden: true})
  end

  def invisible_status_placeholder
    helpers.content_tag(:span, "", class: "bops-sidebar__task-icon", aria: {hidden: true})
  end

  def current_task?(task)
    current_slug = params[:slug]
    return false if current_slug.blank?

    task.full_slug == current_slug
  end
end
