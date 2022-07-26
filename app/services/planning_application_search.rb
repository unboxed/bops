# frozen_string_literal: true

class PlanningApplicationSearch
  include ActiveModel::Model

  attr_accessor :query, :planning_applications

  validates :query, presence: true

  def results
    if valid?
      planning_applications.where(
        "LOWER(reference) LIKE ?", "%#{query.downcase}%"
      )
    else
      planning_applications
    end
  end
end
