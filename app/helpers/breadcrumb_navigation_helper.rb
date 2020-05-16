module BreadcrumbNavigationHelper
  PLANNING_APPLICATION_REGEX = /planning_applications\/[0-9]+\//

  def ensure_navigation
    @navigation ||= [ { title: "Home", path: root_path } ]
  end

  def ensure_planning_application_path(id)
    { title: "Application", path: planning_application_path(id) }
  end

  def navigation_add(title, path)
    if path.match?(PLANNING_APPLICATION_REGEX)
      ensure_navigation << ensure_planning_application_path(params[:planning_application_id]) << { title: title, path: path }
    else
      ensure_navigation << { title: title, path: path }
    end
  end

  def render_navigation
    render partial: "breadcrumb_navigation", locals: { nav: ensure_navigation }
  end
end
