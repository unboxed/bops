# frozen_string_literal: true

module BopsApplicants
  class NeighbourResponseForm
    include ActiveModel::API
    include ActiveModel::Attributes

    STAGES = %w[about_you thoughts response check].freeze
    RESPONSE_TAGS = %i[design use light privacy access noise traffic other].freeze

    PERMITTED_PARAMS = [
      :stage, :movement, neighbour_response: [
        :name, :email, :address, :summary_tag, *RESPONSE_TAGS, files: [], tags: []
      ]
    ].freeze

    attribute :name, :string
    attribute :email, :string
    attribute :address, :string
    attribute :summary_tag, :string
    attribute :tags, array: true, default: -> { [] }
    attribute :files, array: true, default: -> { [] }

    RESPONSE_TAGS.each do |tag|
      attribute tag, :string
    end

    with_options on: %i[about_you check] do
      validates :name, presence: true
      validates :email, format: {with: URI::MailTo::EMAIL_REGEXP}, allow_blank: true
    end

    with_options on: %i[thoughts check] do
      validates :summary_tag, presence: true
    end

    with_options on: %i[response check] do
      validates :tags, presence: true

      RESPONSE_TAGS.each do |tag|
        validates tag, presence: true, if: -> { tags.include?(tag.to_s) }
      end
    end

    class << self
      def model_name
        @_model_name ||= ActiveModel::Name.new(self, nil, "NeighbourResponse")
      end
    end

    def initialize(planning_application, params)
      @planning_application = planning_application
      @params = params.permit(PERMITTED_PARAMS)

      super(neighbour_response_params)
    end

    def failed?
      done? && errors.any?
    end

    def files=(value)
      super(Array.wrap(value).compact_blank)
    end

    def persisted?
      false
    end

    def response_tags
      RESPONSE_TAGS
    end

    def save
      if moving_backwards?
        @stage = previous_stage and return false
      end

      unless valid?(stage.to_sym)
        return false
      end

      if done?
        create_neighbour_response
      else
        @stage = next_stage and return false
      end
    end

    def stage
      @stage ||= stage_param.in?(STAGES) ? stage_param : STAGES.first
    end

    def tags=(value)
      super(filter_tags(Array.wrap(value).compact_blank))
    end

    def to_partial_path
      "bops_applicants/neighbour_responses/#{stage}"
    end

    private

    attr_reader :params, :planning_application

    delegate :consultation, to: :planning_application
    delegate :documents, to: :planning_application
    delegate :neighbours, to: :consultation

    def all_comments
      tags.map { |tag| normalize_lines(attributes[tag]) }.join("\n\n")
    end

    def create_neighbour_response
      transaction do
        neighbour = find_or_create_neighbour

        response = neighbour.neighbour_responses.create! do |r|
          r.name = name
          r.email = email
          r.summary_tag = summary_tag
          r.tags = tags
          r.response = all_comments
          r.received_at = Time.zone.now
        end

        files.each do |file|
          documents.create!(file: file, neighbour_response: response)
        end
      end

      true
    rescue
      false
    end

    def done?
      stage == STAGES.last
    end

    def filter_tags(unfiltered_tags)
      unfiltered_tags.select { |tag| RESPONSE_TAGS.include?(tag.to_sym) }
    end

    def find_or_create_neighbour
      neighbours.find_or_create_by!(address:) do |n|
        n.selected = false
        n.source = "sent_comment"
      end
    end

    def movement_param
      params.fetch(:movement, "forwards")
    end

    def moving_backwards?
      movement_param == "backwards"
    end

    def neighbour_response_params
      params.fetch(:neighbour_response, {})
    end

    def next_stage
      STAGES[[stage_index + 1, 3].min]
    end

    def normalize_lines(str)
      str.encode(str.encoding, universal_newline: true)
    end

    def previous_stage
      STAGES[[stage_index - 1, 0].max]
    end

    def stage_index
      STAGES.index(stage)
    end

    def stage_param
      params.fetch(:stage, STAGES.first)
    end

    def transaction(&)
      ActiveRecord::Base.transaction(&)
    end
  end
end
