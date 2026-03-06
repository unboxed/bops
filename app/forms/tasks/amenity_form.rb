# frozen_string_literal: true

module Tasks
  class AmenityForm < Form
    include AssessmentDetailConcern

    def category = "amenity"
  end
end
