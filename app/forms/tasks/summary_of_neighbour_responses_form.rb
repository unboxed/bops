# frozen_string_literal: true

module Tasks
  class SummaryOfNeighbourResponsesForm < Form
    self.task_actions = %w[save_and_complete save_draft]

    ALL_TAGS = (NeighbourResponse::TAGS.dup << :untagged).freeze
    ENTRY_BOUNDARY = /(?=#{ALL_TAGS.map { |t| Regexp.escape("#{t.to_s.humanize}: ") }.join("|")})/

    NeighbourResponse::TAGS.each { |tag| attribute tag, :string }
    attribute :untagged, :string

    after_initialize do
      @assessment_detail = planning_application.assessment_details.find_or_initialize_by(category: "neighbour_summary")
      @neighbour_responses = planning_application.consultation.neighbour_responses
      populate_from_entry
    end

    attr_reader :assessment_detail, :neighbour_responses

    with_options on: :save_and_complete do
      validate :all_summaries_present, if: :neighbour_responses?
    end

    private

    def all_summaries_present
      required_tags = NeighbourResponse::TAGS.select { |tag|
        @neighbour_responses.any? { |r| r.tags.include?(tag.to_s) }
      }
      required_tags << :untagged if @neighbour_responses.without_tags.any?

      missing = required_tags.reject { |tag| public_send(tag).present? }
      errors.add(:base, "Fill in all summaries of comments") if missing.any?
    end

    def neighbour_responses?
      @neighbour_responses.any?
    end

    def populate_from_entry
      return unless (entry = @assessment_detail.entry.presence)
      entry.split(ENTRY_BOUNDARY).each do |segment|
        tag = ALL_TAGS.find { |t| segment.start_with?("#{t.to_s.humanize}: ") }
        next unless tag
        public_send(:"#{tag}=", segment.delete_prefix("#{tag.to_s.humanize}: ").chomp)
      end
    end

    def formatted_entry
      ALL_TAGS.filter_map do |tag|
        value = public_send(tag)
        "#{tag.to_s.humanize}: #{value}\n" if value.present?
      end.join
    end

    def save_draft
      transaction do
        @assessment_detail.update!(entry: formatted_entry, assessment_status: :in_progress, user: Current.user)
        super
      end
    end

    def save_and_complete
      transaction do
        @assessment_detail.update!(entry: formatted_entry, assessment_status: :complete, user: Current.user)
        super
      end
    end
  end
end
