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
      target = if task.legacy_url.present?
        route_for(task.legacy_url, planning_application)
      else
        BopsPreapps::Engine.routes.url_helpers.task_path(@case_record,
          slug: task.full_slug, reference: planning_application_reference)
      end
      link = helpers.govuk_link_to(task.name, target)
      content = safe_join([status_indicator_for(task), link], " ")
      helpers.tag.li(content, class: "bops-sidebar__task")
    end
  end

  def render_section(section)
    elements = []
    elements << helpers.tag.h3(section.section, class: "govuk-heading-s")
    tasks = section.tasks.map { |task| render_task(task) }
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
    icon_markup = helpers.render("shared/icons/#{icon_partial_for(task.status)}")
    helpers.content_tag(:span, icon_markup, class: "bops-sidebar__task-icon", aria: {hidden: true})
  end

  def icon_partial_for(status)
    %w[not_started completed in_progress cannot_start_yet action_required].include?(status) ? status : "in_progress"
  end
end
