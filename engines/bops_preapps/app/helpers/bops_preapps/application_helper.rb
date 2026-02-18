# frozen_string_literal: true

module BopsPreapps
  module ApplicationHelper
    include BopsCore::ApplicationHelper
    include BopsCore::DocumentHelper
    include ::DocumentHelper
    include ::ValidationRequestHelper
    include BreadcrumbNavigationHelper
    include ::ConsulteesHelper
  end
end
