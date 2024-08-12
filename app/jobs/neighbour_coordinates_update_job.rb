# frozen_string_literal: true

class NeighbourCoordinatesUpdateJob < ApplicationJob
  queue_as :low_priority

  def perform(*)
    NeighbourCoordinatesUpdateService.call(*)
  end
end
