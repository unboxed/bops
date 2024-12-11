# frozen_string_literal: true

class PreapplicationService < ApplicationRecord
  belongs_to :planning_application

  TYPES = %i[
    written_advice
    1-2-1_meeting
    site_visit
  ].freeze

  def name
    super.to_sym
  end
end
