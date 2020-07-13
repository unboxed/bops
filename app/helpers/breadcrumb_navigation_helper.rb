# frozen_string_literal: true

module BreadcrumbNavigationHelper
  def add_parent_breadcrumb_link(title, path)
    navigation << { title: title, path: path }
  end

  def render_navigation
    render partial: "breadcrumb_navigation", locals: { nav: navigation }
  end

  private

  # rubocop:disable Rails/HelperInstanceVariable
  def navigation
    @_navigation ||= []
  end
  # rubocop:enable Rails/HelperInstanceVariable
end
