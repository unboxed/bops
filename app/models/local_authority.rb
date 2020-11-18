# frozen_string_literal: true

class LocalAuthority < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :planning_applications, dependent: :destroy
end
