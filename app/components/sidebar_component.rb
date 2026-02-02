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

  def render_task(task, top_level: true)
    if task.section.present?
      render_section(task, top_level:)
    else
      is_active = current_task?(task)
      target = if planning_application.pre_application?
        BopsPreapps::Engine.routes.url_helpers.task_path(@case_record,
          slug: task.full_slug, reference: planning_application_reference)
      else
        task_path(planning_application_reference, slug: task.full_slug)
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

  def render_section(section, top_level: true)
    visible_tasks = section.tasks.reject(&:hidden?)
    return if visible_tasks.empty?

    elements = []

    if planning_application.pre_application? && section.section == "Assessment"
      elements << helpers.govuk_link_to(
        helpers.safe_join([
          helpers.render("shared/icons/envelope", class: "bops-sidebar__task-icon"),
          "Consultation"
        ]),
        BopsPreapps::Engine.routes.url_helpers.task_path(
          planning_application,
          consultation_task
        ),
        class: "bops-sidebar__link"
      )

      elements << helpers.tag.hr(class: "govuk-!-margin-bottom-4")

    elsif planning_application.pre_application? && section.section == "Consultation"

      elements << helpers.govuk_link_to(
        helpers.safe_join([
          helpers.render("shared/icons/envelope", class: "bops-sidebar__task-icon"),
          "Assessment"
        ]),
        BopsPreapps::Engine.routes.url_helpers.task_path(
          planning_application,
          assessment_task
        ),
        class: "bops-sidebar__link"
      )

      elements << helpers.tag.hr(class: "govuk-!-margin-bottom-4")
    end

    toggle_data = if top_level
      {
        sidebar_toggle_target: "button",
        action: "click->sidebar-toggle#toggle"
      }
    else
      {}
    end
    elements << helpers.tag.h3(class: "govuk-heading-s #{"bops-sidebar__toggle" if top_level}",
      data: toggle_data) do
      section.section + " tasks"
    end

    if planning_application.pre_application? && section.section == "Assessment"
      elements << helpers.tag.div(
        helpers.govuk_link_to(
          "Preview report",
          bops_reports.planning_application_path(
            planning_application,
            view_as: "applicant"
          ),
          new_tab: true,
          id: "preview-report-button-link"
        ),
        class: "govuk-!-margin-bottom-4"
      )
    end
    tasks = visible_tasks.map { |task| render_task(task, top_level: false) }
    elements << helpers.tag.ul(safe_join(tasks), class: "govuk-list govuk-list--spaced bops-sidebar__list", data: {sidebar_toggle_target: top_level ? "content" : nil})

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

  def consultation_task
    @planning_application.case_record.tasks.find_by(section: "Consultation")&.first_child
  end

  def assessment_task
    @planning_application.case_record.tasks.find_by(section: "Assessment")&.first_child
  end
end
