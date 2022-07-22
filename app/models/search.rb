# frozen_string_literal: true

class Search
  include ActiveModel::Model

  attr_accessor :query, :planning_application_ids

  validates :query, presence: true

  def results
    if valid?
      planning_applications.where("reference LIKE ?", "%#{query}%")
    else
      planning_applications
    end
  end

  def planning_applications
    PlanningApplication.where(id: planning_application_ids)
  end
end
