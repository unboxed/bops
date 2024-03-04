# frozen_string_literal: true

class Informative < ApplicationRecord
  belongs_to :planning_application

  validates :title, :text, presence: true
end
