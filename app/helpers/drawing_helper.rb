# frozen_string_literal: true

module DrawingHelper
  def filter_archived(drawings)
    drawings.select { |plan| plan.archived? == true }
  end

  def filter_current(drawings)
    drawings.select { |plan| plan.archived? == false }.sort_by(&:archived_at)
  end
end
