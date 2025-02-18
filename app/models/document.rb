# frozen_string_literal: true

class Document < ApplicationRecord
  class Routing
    include Rails.application.routes.url_helpers
    include Rails.application.routes.mounted_helpers

    def initialize(subdomain)
      @subdomain = subdomain
    end

    def default_url_options
      {host: "#{subdomain}.#{domain}"}
    end

    private

    attr_reader :subdomain

    def domain
      Rails.configuration.domain
    end
  end

  class NotArchiveableError < StandardError; end

  belongs_to :planning_application

  with_options optional: true do
    belongs_to :api_user
    belongs_to :document_checklist_item
    belongs_to :evidence_group
    belongs_to :neighbour_response
    belongs_to :owner, polymorphic: true
    belongs_to :site_notice
    belongs_to :site_visit
    belongs_to :user
  end

  has_one :replacement_document_validation_request,
    lambda { |document|
      unscope(:where).where(old_document_id: document.id, cancelled_at: nil)
    },
    dependent: :destroy,
    inverse_of: false

  delegate :audits, to: :planning_application
  delegate :local_authority, to: :planning_application
  delegate :blob, :representable?, to: :file

  include Auditable

  has_one_attached :file, dependent: :destroy
  after_create :create_audit!
  before_update :reset_replacement_document_validation_request_update_counter!, if: :owner_is_validation_request?
  after_update :audit_updated!

  DRAWING_TAGS = %w[
    elevations.existing
    elevations.proposed
    floorPlan.existing
    floorPlan.proposed
    internalElevations
    internalSections
    locationPlan
    otherDrawing
    roofPlan.existing
    roofPlan.proposed
    sections.existing
    sections.proposed
    sitePlan.existing
    sitePlan.proposed
    sketchPlan
    streetScene
    treePlan
    unitPlan.existing
    unitPlan.proposed
    usePlan.existing
    usePlan.proposed
  ].freeze

  EVIDENCE_TAGS = %w[
    bankStatement
    buildingControlCertificate
    constructionInvoice
    councilTaxBill
    otherEvidence
    photographs.existing
    photographs.proposed
    statutoryDeclaration
    tenancyAgreement
    tenancyInvoice
    utilitiesStatement
    utilityBill
  ].freeze

  SUPPORTING_DOCUMENT_TAGS = %w[
    accessRoadsRightsOfWayDetails
    affordableHousingStatement
    arboriculturistReport
    basementImpactStatement
    bioaerosolAssessment
    birdstrikeRiskManagementPlan
    boreholeOrTrialPitAnalysis
    conditionSurvey
    contaminationReport
    crimePreventionStrategy
    designAndAccessStatement
    disabilityExemptionEvidence
    ecologyReport
    emissionsMitigationAndMonitoringScheme
    energyStatement
    environmentalImpactAssessment
    externalMaterialsDetails
    fireSafetyReport
    floodRiskAssessment
    foulDrainageAssessment
    geodiversityAssessment
    hedgerowsInformation
    hedgerowsInformation.plantingDate
    heritageStatement
    hydrologicalAssessment
    hydrologyReport
    internal.appeal
    internal.appealDecision
    internal.pressNotice
    internal.siteNotice
    internal.siteVisit
    joinersReport
    joinerySections
    landContaminationAssessment
    landscapeAndVisualImpactAssessment
    landscapeStrategy
    lightingAssessment
    litterVerminAndBirdControlDetails
    methodStatement
    mineralsAndWasteAssessment
    necessaryInformation
    newDwellingsSchedule
    noiseAssessment
    openSpaceAssessment
    otherDocument
    otherSupporting
    parkingPlan
    planningStatement
    recycleWasteStorageDetails
    relevantInformation
    residentialUnitsDetails
    statementOfCommunityInvolvement
    storageTreatmentAndWasteDisposalDetails
    subsidenceReport
    sunlightAndDaylightReport
    sustainabilityStatement
    technicalEvidence
    technicalSpecification
    townCentreImpactAssessment
    townCentreSequentialAssessment
    transportAssessment
    travelPlan
    treeAndHedgeLocation
    treeAndHedgeRemovedOrPruned
    treeCanopyCalculator
    treeConditionReport
    treesReport
    ventilationStatement
    viabilityAppraisal
    visualisations
    wasteAndRecyclingStrategy
    wasteStorageDetails
    waterEnvironmentAssessment
  ].freeze

  ## Needs to be better
  EVIDENCE_QUESTIONS = {
    utilityBill: [
      "What do these utility bills show?",
      "What date do these utility bills start from?",
      "What date do these utility bills run until?"
    ],
    "photographs.existing": ["What do these photographs show?"],
    "photographs.proposed": ["What do these photographs show?"],
    buildingControlCertificate: [
      "When was this building control certificate issued?",
      "What do these building control certificates show?"
    ],
    constructionInvoice: ["What do these construction invoices show?"],
    councilTaxBill: [
      "What date do these council tax bills start from?",
      "When do these councils tax bills run until?",
      "What do these Council Tax documents show?"
    ],
    tenancyAgreement: [
      "What date do these tenancy agreements start from?",
      "When do these tenancy agreements run until?",
      "What do these tenancy agreements show?"
    ],
    tenancyInvoice: [
      "What date do these tenancy invoices start from?",
      "When do these tenancy invoices run until?",
      "What do these tenancy invoices show?"
    ],
    bankStatement: [
      "What date do these bank statements start from?",
      "When do these bank statements run until?",
      "What do these bank statements show?"
    ],
    otherEvidence: ["What do these documents show?"]
  }.freeze

  DEFAULT_TABS = ["All", "Drawings", "Supporting documents", "Evidence"].freeze
  TAGS_MAP = {
    "Drawings" => DRAWING_TAGS,
    "Supporting documents" => SUPPORTING_DOCUMENT_TAGS,
    "Evidence" => EVIDENCE_TAGS
  }.freeze

  TAGS = DRAWING_TAGS + EVIDENCE_TAGS + SUPPORTING_DOCUMENT_TAGS

  PERMITTED_CONTENT_TYPES = ["application/pdf", "image/png", "image/jpeg"].freeze
  EXCLUDED_OWNERS = %w[PressNotice SiteNotice SiteVisit Appeal].freeze

  attr_accessor :replacement_file

  validate :no_open_replacement_request, if: :replacement_file
  validate :tag_values_permitted
  validate :file_content_type_permitted
  validate :file_attached
  validate :numbered
  validate :created_date_is_in_the_past

  scope :no_owner, -> { where(owner_type: nil) }
  scope :not_excluded_owners, -> { where.not(owner_type: EXCLUDED_OWNERS) }
  scope :default, -> { no_owner.or(not_excluded_owners) }
  scope :by_created_at, -> { order(created_at: :asc) }
  scope :active, -> { default.where(archived_at: nil) }
  scope :invalidated, -> { where(validated: false) }
  scope :validated, -> { where(validated: true) }
  scope :redacted, -> { where(redacted: true) }
  scope :not_redacted, -> { where.not(redacted: true) }
  scope(
    :referenced_in_decision_notice,
    -> { where(referenced_in_decision_notice: true) }
  )
  scope :publishable, -> { where(publishable: true) }

  scope :for_publication, -> { publishable }
  scope :for_display, -> { referenced_in_decision_notice }

  scope :with_tag, ->(tag) { where(arel_table[:tags].contains(Array.wrap(tag))) }
  scope :with_siteplan_tags, -> { where(arel_table[:tags].overlaps(%w[sitePlan.existing sitePlan.proposed])) }
  scope :with_drawing_tags, -> { where(arel_table[:tags].overlaps(DRAWING_TAGS)) }
  scope :with_file_attachment, -> { includes(file_attachment: :blob) }
  scope :for_site_visit, -> { where.not(site_visit_id: nil) }
  scope :for_fee_exemption, -> { with_tag("disabilityExemptionEvidence") }
  scope :not_for_fee_exemption, -> { where.not(arel_table[:tags].contains(%w[disabilityExemptionEvidence])) }

  before_validation on: :create do
    if owner.present?
      self.planning_application ||= owner.planning_application
    end
  end

  before_create do
    self.api_user ||= Current.api_user
    self.user ||= Current.user
  end

  class << self
    def tags(key)
      case key.to_s
      when "drawings"
        DRAWING_TAGS
      when "evidence"
        EVIDENCE_TAGS
      when "supporting_documents"
        (SUPPORTING_DOCUMENT_TAGS - ["disabilityExemptionEvidence"])
      when "other"
        []
      else
        raise ArgumentError, "Unexpected document tag type: #{key}"
      end
    end
  end

  def name
    file.filename.to_s if file.attached?
  end

  def archived?
    archived_at.present?
  end

  def unarchived?
    !archived?
  end

  def referenced_in_decision_notice?
    referenced_in_decision_notice == true
  end

  def archive(archive_reason)
    if replacement_document_validation_request.try(:open_or_pending?)
      raise NotArchiveableError,
        "Cannot archive document with an open or pending validation request"
    end

    return if archived?

    transaction do
      update!(archive_reason:, archived_at: Time.zone.now)
      audit!(activity_type: "archived", activity_information: file.filename, audit_comment: archive_reason)
    end
  end

  def unarchive!
    transaction do
      update!(archived_at: nil)
      audit!(activity_type: "unarchived", activity_information: file.filename)
    end
  end

  def published?
    publishable? && unarchived?
  end

  def received_at_or_created
    (received_at || created_at).to_date.to_fs
  end

  def audit_updated!
    return unless saved_changes?

    if saved_change_to_attribute?("received_at")
      audit!(activity_type: "document_received_at_changed", activity_information: file.filename,
        audit_comment: audit_date_comment)
    end
    if saved_change_to_attribute?(:validated, from: false, to: true)
      audit!(activity_type: "document_changed_to_validated", activity_information: file.filename)
    elsif saved_change_to_attribute?(:validated, to: false)
      audit!(activity_type: "document_invalidated", activity_information: file.filename,
        audit_comment: invalidated_document_reason)
    end
  end

  def invalidated_document_reason
    replacement_document_validation_request.try(:reason) || super
  end

  def update_or_replace(attributes)
    self.attributes = attributes
    self.replacement_file = attributes[:file]
    return false unless valid?

    if replacement_file.present?
      planning_application.documents.create!(attributes)
      reload.archive(I18n.t("document.replacement_document_uploaded"))
    else
      save!
    end
  end

  def blob_url
    routes.uploaded_file_url(blob).presence
  end

  def representation(transformations = {resize_to_limit: [1000, 1000]})
    file.representation(transformations).processed
  rescue ActiveStorage::Error => e
    logger.warn("Image retrieval failed for document ##{id} with error '#{e.message}'")
    nil
  end

  def representation_url(transformations = {resize_to_limit: [1000, 1000]})
    routes.uploaded_file_url(representation(transformations)).presence
  end

  private

  def routes
    @_routes ||= Routing.new(local_authority.subdomain)
  end

  def no_open_replacement_request
    return unless replacement_document_validation_request&.open_or_pending?

    errors.add(:file, :open_replacement_request)
  end

  def tag_values_permitted
    errors.add(:tags, :unpermitted_tags) unless (tags - Document::TAGS).empty?
  end

  def file_content_type_permitted
    return unless file.attached? && file.blob&.content_type

    errors.add(:file, :unsupported_file_type) unless PERMITTED_CONTENT_TYPES.include? file.blob.content_type
  end

  def file_attached
    errors.add(:file, :missing_file) unless file.attached?
  end

  def numbered
    errors.add(:numbers, :missing_numbers) if referenced_in_decision_notice? && numbers.blank?
  end

  def created_date_is_in_the_past
    return unless received_at.present? && received_at > Time.zone.today

    errors.add(:received_at, "Date must be today or earlier. You cannot insert a future date.")
  end

  def create_audit!
    audit!(activity_type: "uploaded", activity_information: file.filename)
  end

  def audit_date_comment
    {previous_received_date: saved_change_to_received_at.first,
     updated_received_date: saved_change_to_received_at.second}.to_json
  end

  def owner_is_validation_request?
    owner.present? && owner.is_a?(ValidationRequest)
  end

  def reset_replacement_document_validation_request_update_counter!
    return unless validated? || archived?

    owner.reset_update_counter!
  end
end
