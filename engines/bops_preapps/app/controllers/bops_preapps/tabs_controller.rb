# frozen_string_literal: true

module BopsPreapps
  class TabsController < AuthenticationController
    include BopsCore::TabsController

    private

    def filtered_applications
      search.filtered_planning_applications(search.pre_applications)
    end

    def closed_applications
      search.closed_planning_applications(search.pre_applications)
    end
  end
end
