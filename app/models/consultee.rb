# frozen_string_literal: true

class Consultee < ApplicationRecord
  belongs_to :planning_application

  validates :name, :origin, presence: true

  enum origin: { internal: 0, external: 1 }
end
