# frozen_string_literal: true

class Consultee < ApplicationRecord
  belongs_to :consultation
  has_many :emails, dependent: :destroy
  has_many :responses, dependent: :destroy

  validates :name, presence: true

  enum :origin, {
    internal: "internal",
    external: "external"
  }, scopes: false

  enum :status, {
    not_consulted: "not_consulted",
    consulted: "consulted",
    failed: "failed"
  }, scopes: false

  class << self
    def with_response
      preload(:responses)
    end
  end

  def expires_at
    (email_sent_at + 21.days).at_end_of_day
  end

  def expired?(now = Time.current)
    email_sent_at ? now > expires_at : false
  end

  def period(now = Time.current)
    email_sent_at? ? ((expires_at - now) / 86_400.0).floor.abs : nil
  end
end
