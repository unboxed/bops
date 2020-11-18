# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  enum role: { assessor: 0, reviewer: 1, admin: 2 }

  devise :database_authenticatable, :recoverable,
         :rememberable, :validatable

  acts_as_tenant(:local_planning_authority)

  has_many :decisions, dependent: :restrict_with_exception
  has_many :planning_applications, through: :decisions
end
