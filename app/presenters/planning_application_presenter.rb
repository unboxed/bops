# frozen_string_literal: true

class PlanningApplicationPresenter
  attr_reader :template, :planning_application

  delegate :tag, :concat, :link_to, to: :template
  delegate :to_param, to: :planning_application

  STATUS_COLOURS = {
    invalidated: "yellow",
    not_started: "grey",
    in_assessment: "turquoise",
    awaiting_determination: "purple",
    awaiting_correction: "green"
  }.freeze

  def initialize(template, planning_application)
    @template = template
    @planning_application = planning_application
  end

  def method_missing(symbol, *args)
    if planning_application.respond_to?(symbol)
      planning_application.send(symbol, *args)
    else
      super
    end
  end

  def respond_to_missing?(symbol, include_private = false)
    super || planning_application.respond_to?(symbol)
  end

  concerning :Status do
    def status_tag
      classes = ["govuk-tag govuk-tag--#{status_tag_colour}"]

      tag.span class: classes do
        determined? ? decision.humanize : status.humanize
      end
    end

    def remaining_days_status_tag
      classes = ["govuk-tag govuk-tag--#{status_date_tag_colour}"]

      tag.span class: classes do
        if expiry_date.past?
          I18n.t("planning_applications.overdue", count: days_overdue)
        else
          I18n.t("planning_applications.days_left", count: days_left)
        end
      end
    end

    def next_relevant_date_tag
      tag.strong(next_date_label) + tag.span(next_date)
    end

    def next_date_label
      if in_progress?
        "Expiry date: "
      elsif determined?
        "#{decision.humanize} at: "
      else
        "#{status.humanize} at: "
      end
    end

    def next_date
      if in_progress?
        expiry_date
      else
        send("#{status}_at")
      end
    end
  end

  concerning :ProposalDetails do
    def proposal_question(proposal)
      tag.p(class: "govuk-body") do
        tag.strong(proposal.question)
      end
    end

    def proposal_responses(proposal)
      tag.p(class: "govuk-body") do
        proposal.responses.map(&:value).compact.join(", ")
      end
    end

    def proposal_policy_refs(proposal)
      refs = proposal.metadata.policy_refs

      refs.map do |ref|
        if ref.url.present?
          link_to(ref.url, ref.url, class: "govuk-link")
        else
          ref.text
        end
      end.join
    end

    def proposal_metadata(proposal)
      metadata = proposal.metadata

      return if metadata.nil?

      tag.div do
        concat tag.p(tag.em(metadata.notes)) if metadata.notes.present?
        concat tag.p(tag.em("Auto-answered by RIPA")) if metadata.auto_answered.present?
        concat proposal_policy_refs(proposal) if metadata.policy_refs.present?
      end
    end

    def proposal_detail_item(proposal)
      tag.p(class: "govuk-body") do
        proposal_question(proposal) +
          proposal_responses(proposal) +
          proposal_metadata(proposal)
      end
    end
  end

  private

  def status_tag_colour
    if planning_application.determined?
      planning_application.granted? ? "green" : "red"
    else
      colour = STATUS_COLOURS[planning_application.status.to_sym]

      colour || "grey"
    end
  end

  def status_date_tag_colour
    return "grey" if @planning_application.determined?

    number = planning_application.days_left

    if number > 11
      "green"
    elsif number.between?(6, 10)
      "yellow"
    else
      "red"
    end
  end
end
