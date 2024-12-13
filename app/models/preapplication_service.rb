# frozen_string_literal: true

class PreapplicationService < AdditionalService
  TYPES = %i[
    written_advice
    meeting
    site_visit
  ].freeze
end
