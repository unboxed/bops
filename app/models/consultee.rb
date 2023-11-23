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

  def suffix?
    role? || organisation?
  end

  def suffix
    [role, organisation].compact_blank.join(", ").presence
  end

  def expired?(now = Time.current)
    expires_at && now > expires_at
  end

  def expires_at
    super || default_expires_at
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

  delegate :received_at, to: :last_response, prefix: :last, allow_nil: true

  private

  def default_expires_at
    email_delivered_at && (email_delivered_at + 21.days).end_of_day
  end
end
