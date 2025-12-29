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
  end
end
