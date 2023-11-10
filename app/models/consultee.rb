# frozen_string_literal: true

class Consultee < ApplicationRecord
  attribute :selected, :boolean, default: false

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
    sending: "sending",
    awaiting_response: "awaiting_response",
    failed: "failed",
    responded: "responded"
  }, scopes: false

  class << self
    def default_scope
      preload(:responses)
    end
  end

  def expires_at
    (email_delivered_at + 21.days).at_end_of_day
  end

  def expired?(now = Time.current)
    email_delivered_at ? now > expires_at : false
  end

  def period(now = Time.current)
    email_delivered_at? ? ((expires_at - now) / 86_400.0).floor.abs : nil
  end
end
