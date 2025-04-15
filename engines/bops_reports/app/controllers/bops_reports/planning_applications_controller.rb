# frozen_string_literal: true

module BopsReports
  class PlanningApplicationsController < PlanningApplications::BaseController
    include BopsCore::MagicLinkAuthenticatable

    before_action :authenticate_with_sgid!, only: :show, unless: :user_signed_in?

    def show
      respond_to do |format|
        format.html
      end
    end
  end
end
