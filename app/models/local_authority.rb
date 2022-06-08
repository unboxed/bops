# frozen_string_literal: true

class LocalAuthority < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :planning_applications, dependent: :destroy

  validates :council_code, :name, :subdomain, presence: true

  enum subdomain: {
    lambeth: "lambeth",
    southwark: "southwark",
    buckinghamshire: "buckinghamshire",
    ripa: "ripa"
  }

  def signatory
    "#{signatory_name}, #{signatory_job_title}"
  end
end
