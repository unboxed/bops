# frozen_string_literal: true

module BopsPreapps
  module ApplicationHelper
    include BopsCore::ApplicationHelper
    include BopsCore::DocumentHelper
    include ::DocumentHelper
    include ::ValidationRequestHelper
    include BreadcrumbNavigationHelper
    include ::ConsulteesHelper

    def return_to_hidden_field
      return if params[:return_to].blank?

      hidden_field_tag :return_to, params[:return_to]
    end

    def return_to_or_task_path(planning_application, task)
      params[:return_to].presence || task_path(planning_application, task)
    end
  end
end
