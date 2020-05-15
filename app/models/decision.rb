# frozen_string_literal: true

class Decision < ApplicationRecord
  belongs_to :planning_application
  belongs_to :user

  validates :granted, inclusion: { in: [true, false] }
end
