# frozen_string_literal: true

class Enforcement::Activity < ApplicationRecord
  include DateValidateable

  belongs_to :enforcement
end
