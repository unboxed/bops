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
          slug: subsubtask.slug, reference: planning_application_reference)
      end
      link = helpers.govuk_link_to(task.name, target)
      helpers.tag.li(link)
    end
  end

  def render_section(section)
    elements = []
    elements << helpers.tag.h3(section.section, class: "govuk-heading-s")
    tasks = section.tasks.map { |task| render_task(task) }
    elements << helpers.tag.ul(safe_join(tasks), class: "govuk-list")

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
end
