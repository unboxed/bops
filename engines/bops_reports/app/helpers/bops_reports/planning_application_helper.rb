# frozen_string_literal: true

module BopsReports
  module PlanningApplicationHelper
    def applicant_view?
      current_user.nil? || params[:view_as] == "applicant"
    end

    def editing_enabled?
      current_user.present? &&
        !applicant_view? &&
        !@planning_application.determined?
    end
  end
end
