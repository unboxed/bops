# frozen_string_literal: true

module Tasks
  class SiteDescriptionForm < Form
    include AssessmentDetailConcern

    def category = "site_description"
  end
end
