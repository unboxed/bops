# frozen_string_literal: true

module BreadcrumbNavigationHelper
  PLANNING_APPLICATION_REGEX = /planning_applications\/[0-9]+\//

  def navigation_add(title, path)
    if path.match?(PLANNING_APPLICATION_REGEX)
      ensure_navigation <<
          ensure_planning_application_path(params[:planning_application_id]) <<
          { title: title, path: path }
    else
      ensure_navigation << { title: "Application", path: nil }
    end
  end

  def render_navigation
    render partial: "breadcrumb_navigation", locals: { nav: ensure_navigation }
  end

  private

  # rubocop:disable Rails/HelperInstanceVariable
  def ensure_navigation
    @navigation ||= home_navigation_path
  end
  # rubocop:enable Rails/HelperInstanceVariable

  def home_navigation_path
    [ { title: "Home", path: root_path } ]
  end

  def ensure_planning_application_path(id)
    { title: "Application", path: planning_application_path(id) }
  end
end
