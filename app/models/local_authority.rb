# frozen_string_literal: true

class LocalAuthority < ApplicationRecord
  validates :subdomain, uniqueness: true

  has_many :users, dependent: :destroy
  has_many :planning_applications, dependent: :destroy
end
