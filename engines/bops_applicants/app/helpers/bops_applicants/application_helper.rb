# frozen_string_literal: true

module BopsApplicants
  module ApplicationHelper
    def page_title
      t(:page_title, scope: "bops_applicants", council: current_local_authority.short_name)
    end

    def staging_environment?
      BopsApplicants.env.staging?
    end
  end
end
