# frozen_string_literal: true

class SiteHistory < ApplicationRecord
  belongs_to :planning_application

  validates :date, :application_number, :description, :decision, presence: true
end
