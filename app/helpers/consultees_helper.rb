# frozen_string_literal: true

module ConsulteesHelper
  ConsulteeTab = Struct.new(:key, :title, :heading, :consultees, keyword_init: true)

  STATUS_LABELS = {
    approved: "No objection",
    amendments_needed: "Amendments needed",
    objected: "Objection"
  }.freeze

  def consultee_presenters(consultees, planning_application)
    consultees.map do |consultee|
      ConsulteePresenter.new(consultee, planning_application:, view_context: self)
    end
  end

  def consultee_tabs(consultee_presenters)
    tabs = [ConsulteeTab.new(key: :all, title: tab_title("All", consultee_presenters.size), heading: "All responses", consultees: consultee_presenters)]

    consultee_response_filters.each do |summary_tag, label|
      filtered = consultee_presenters.select { |presenter| presenter.summary_tag == summary_tag.to_s }
      next if filtered.empty?

      heading =
        case summary_tag.to_sym
        when :approved then "Responses with no objections"
        when :objected then "Objections received"
        when :amendments_needed then "Responses requesting amendments"
        else label
        end

      tabs << ConsulteeTab.new(key: summary_tag, title: tab_title(label, filtered.size), heading:, consultees: filtered)
    end

    tabs
  end

  private

  def consultee_response_filters
    Consultee::Response.summary_tags.keys.index_with do |tag|
      STATUS_LABELS.fetch(tag.to_sym) do
        I18n.t("consultee_response.summary_tags.#{tag}", default: tag.to_s.humanize)
      end
    end
  end

  def tab_title(label, count)
    "#{label} (#{count})"
  end
end
