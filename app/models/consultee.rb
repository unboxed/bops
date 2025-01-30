# frozen_string_literal: true

class Consultee < ApplicationRecord
  class Routing
    include Rails.application.routes.url_helpers
    include Rails.application.routes.mounted_helpers

    def initialize(subdomain, planning_application, sgid: nil)
      @subdomain = subdomain
      @planning_application = planning_application
      @sgid = sgid
    end

    def default_url_options
      {host: "#{subdomain}.#{domain}"}
    end

    def consultees_magic_link
      bops_consultees.planning_application_url(
        reference: planning_application.reference, sgid:, subdomain:
      )
    end

    private

    attr_reader :subdomain, :sgid, :planning_application

    def domain
      Rails.configuration.domain
    end
  end

  include BopsCore::MagicLinkable

  attribute :selected, :boolean, default: false

  belongs_to :consultation
  has_many :emails, dependent: :destroy
  has_many :planning_application_constraints, dependent: :destroy
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

  scope :unassigned, -> { where.not(id: PlanningApplicationConstraint.pluck(:consultee_id)) } # rubocop:disable Rails/PluckInWhere

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

  def application_link
    if consultation.planning_application.pre_application?
      routes.consultees_magic_link
    else
      consultation.application_link
    end
  end

  def can_resend_magic_link?
    # Resend if never sent or at least 1 minute has passed
    magic_link_last_sent_at.nil? || magic_link_last_sent_at <= 1.minute.ago
  end

  delegate :received_at, to: :last_response, prefix: :last, allow_nil: true

  private

  def routes
    @_routes ||= Routing.new(
      consultation.local_authority.subdomain, consultation.planning_application, sgid: sgid
    )
  end

  def default_expires_at
    email_delivered_at && (email_delivered_at + Consultation::DEFAULT_PERIOD_DAYS).end_of_day
  end
end
