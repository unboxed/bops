# frozen_string_literal: true

class AdditionalService < ApplicationRecord
  belongs_to :planning_application

  def name
    super.to_sym
  end
end
