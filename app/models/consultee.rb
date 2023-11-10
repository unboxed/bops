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

  def expired?(now = Time.current)
    expires_at && now > expires_at
  end

  def period(now = Time.current)
    (expires_at - now).seconds.in_days.floor
  end

  def consulted?
    !not_consulted?
  end

  def responses?
    responses.present?
  end

  def last_response
    responses.max_by(&:id)
  end
end
