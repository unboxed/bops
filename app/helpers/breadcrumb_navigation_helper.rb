# frozen_string_literal: true

module BreadcrumbNavigationHelper
  def add_parent_breadcrumb_link(title, path)
    navigation[title] = path
  end

  def render_navigation
    return if navigation.blank?
    render GovukComponent::BreadcrumbsComponent.new(breadcrumbs: navigation)
  end

  private

  def navigation
    @navigation ||= {}

    if @planning_application&.pre_application?
      @navigation["Home"] = bops_preapps.root_path
    end

    @navigation
  end
end
