# frozen_string_literal: true

module BopsPreapps
  class TabsController < AuthenticationController
    include BopsCore::TabsController

    def active_page_key
      "pre_applications"
    end

    private

    def pre_application?
      true
    end

    def filtered_applications
      search.filtered_planning_applications(search.pre_applications)
    end

    def closed_applications
      search.closed_planning_applications(search.pre_applications)
    end
  end
end
