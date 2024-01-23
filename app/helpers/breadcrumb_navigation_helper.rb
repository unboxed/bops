# frozen_string_literal: true

module BreadcrumbNavigationHelper
  def add_parent_breadcrumb_link(title, path)
    navigation << {title:, path:}
  end

  def render_navigation
    render partial: "application/breadcrumb_navigation", locals: {nav: navigation}
  end

  private

  def navigation
    @navigation ||= []
  end
end
