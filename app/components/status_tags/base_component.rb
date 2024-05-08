# frozen_string_literal: true

module StatusTags
  class BaseComponent < ViewComponent::Base
    def initialize(status:)
      @status = status
    end

    def render?
      status.present?
    end

    def call
      govuk_tag(text: link_text, colour:, html_attributes: colour ? {} : {class: "govuk-tag--colourless"})
    end

    private

    attr_reader :status

    def link_text
      t("status_tag_component.#{status}")
    end

    def colour
      case status.to_sym
      when :approved, :auto_approved
        "green"
      when :not_started, :new, :review_not_started, :not_consulted
        "blue"
      when :in_progress, :awaiting_response
        "light-blue"
      when :updated, :to_be_reviewed, :submitted, :neutral, :amendments_needed, :awaiting_changes
        "yellow"
      when :refused, :removed, :invalid, :rejected, :objection, :failed, :refused_legal_agreement, :cancelled
        "red"
      end
    end
  end
end
