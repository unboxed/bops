# frozen_string_literal: true

module BopsApi
  class LocalAuthority < ApplicationRecord
    has_many :users
    has_many :planning_applications
  end
end
