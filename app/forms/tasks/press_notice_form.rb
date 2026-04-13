# frozen_string_literal: true

module Tasks
  class PressNoticeForm < Form
    include DateValidateable

    self.task_actions = %w[save_and_complete mark_not_required email_press_notice confirm_publication]

    attribute :required, :boolean
    attribute :reasons, :list, default: []
    attribute :other_reason, :string, default: nil
    attribute :published_at, :date
    attribute :documents, array: true
    attribute :comment, :string

    after_initialize do
      @press_notices = planning_application.press_notices
      @press_notice = if params[:id].present?
        planning_application.press_notices.find(params[:id]).tap do |pn|
          self.published_at ||= pn.published_at
          self.comment ||= pn.comment
          self.documents ||= pn.documents
        end
      else
        planning_application.press_notices.new
      end
    end

    delegate :consultation_end_date, :consultation_start_date, to: :press_notice

    with_options on: :confirm_publication do
      validates :published_at, presence: {message: "Please select when press notice was published"}
      validates :published_at, date: {on_or_before: :consultation_end_date, message: "Date must be on or before the consultation end date"}
      validates :published_at, date: {on_or_after: :consultation_start_date, message: "Date must be on or after the consultation start date"}
    end

    with_options on: :email_press_notice do
      validates :reasons, presence: {message: "Select a reason for the press notice"}
      validates :other_reason, presence: {message: "Provide other reason for press notice"}, if: :other_reason_selected?
    end

    attr_reader :press_notice, :press_notices

    def new_press_notice_url
      route_for(:task, planning_application, slug: task.full_slug, new: true, only_path: true)
    end

    def press_notice_url
      route_for(:task, planning_application, slug: task.full_slug, only_path: true)
    end

    def edit_press_notice_url(press_notice)
      route_for(:edit_task_component, planning_application, slug: task.full_slug, id: press_notice.id, only_path: true)
    end

    private

    def other_reason_selected?
      reasons.include?("other")
    end

    def form_params(params)
      params.fetch(param_key, {}).permit(
        :required,
        :other_reason,
        :published_at,
        :comment,
        reasons: [],
        documents: []
      )
    end

    def mark_not_required
      transaction do
        press_notice.update!(
          required: false
        )
        task.completed!
      end
    end

    def confirm_publication
      transaction do
        press_notice.update!(
          published_at: published_at,
          comment: comment,
          documents: documents
        )
        task.completed!
      end
    end

    def email_press_notice
      transaction do
        press_notice.update!(
          required: true,
          reasons: reasons.flatten,
          other_reason: other_reason
        )
        SendPressNoticeEmailJob.perform_later(press_notice, Current.user)
        task.in_progress!
      end
    end
  end
end
