# frozen_string_literal: true

class LocalAuthority < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :planning_applications, dependent: :destroy

  validates :name, :subdomain, presence: true

  enum subdomain: {
    lambeth: "lambeth",
    southwark: "southwark",
    buckinghamshire: "buckinghamshire",
    ripa: "ripa"
  }

  def signatory
    "#{signatory_name}, #{signatory_job_title}"
  end

  def council_code
    I18n.t("council_code.#{subdomain}")
  end
end
