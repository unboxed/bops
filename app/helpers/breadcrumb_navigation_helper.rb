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
      ensure_navigation <<
          ensure_planning_application_path(params[:planning_application_id]) <<
          { title: title, path: path}
    else
      ensure_navigation << {title: "Application", path: nil}
    end
  end

  def concatenate_nav_elements(nav)
    nav.each do |page|
      if page == ensure_navigation.last
        concat content_tag(:a, page[:title])
      else
        concat content_tag(:a, page[:title], href: page[:path])
        concat " > "
      end
    end
  end

  def create_breadcrumbs
    breadcrumbs = content_tag(:li, class: '"govuk-breadcrumbs__list-item"') do
      unless ensure_navigation.length == 1
        concatenate_nav_elements(ensure_navigation)
      end
    end
    breadcrumbs
  end
end
