# frozen_string_literal: true

class PlanxPlanningData < ApplicationRecord
  belongs_to :planning_application

  validates :entry, presence: true
  validates :session_id, uniqueness: true, allow_nil: true

  def session_id
    super || JSON.parse(entry)["session_id"]
  end
end
