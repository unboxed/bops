# frozen_string_literal: true

class ConsistencyChecklistStatusTagComponent < StatusTagComponent
  def initialize(consistency_checklist:)
    @consistency_checklist = consistency_checklist
  end

  private

  attr_reader :consistency_checklist

  def status
    if consistency_checklist.blank?
      :not_started
    elsif consistency_checklist.in_assessment?
      :in_progress
    else
      :complete
    end
  end
end
