# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :recoverable,
         :rememberable, :validatable

  enum role: { assessor: 0, reviewer: 1, admin: 2 }
  after_initialize :set_default_role, if: :new_record?

  def set_default_role
    self.role ||= :assessor
  end
end
