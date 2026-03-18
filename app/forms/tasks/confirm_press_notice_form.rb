# frozen_string_literal: true

module Tasks
  class ConfirmPressNoticeForm < Form
    include PublicityPermittable
    include DateValidateable

    self.task_actions = %w[save_and_complete confirm_publication]

    attribute :published_at, :date
    attribute :documents, array: true
    attribute :comment, :string

    delegate :consultation_end_date, :consultation_start_date, :requested_at, to: :press_notice

    after_initialize do
      if params[:id].present?
        pn = press_notices.find(params[:id])
        self.published_at ||= pn.published_at
        self.comment ||= pn.comment
        self.documents ||= pn.documents
      end
    end

    with_options on: :confirm_publication do
      validates :published_at, presence: {message: "Please select when press notice was published"}
      validates :published_at, date: {on_or_before: :consultation_end_date, message: "Date must be on or before the consultation end date"}
      validates :published_at, date: {on_or_after: :consultation_start_date, message: "Date must be on or after the consultation start date"}
    end

    with_options on: :save_and_complete do
      validate :all_required_press_notices_published
    end

    def press_notices
      planning_application.press_notices
    end

    def press_notice
      @press_notice ||= if params[:id].present?
        press_notices.find(params[:id])
      else
        press_notices.first
      end
    end

    def edit_press_notice_url(press_notice)
      route_for(:edit_task_component, planning_application, slug: task.full_slug, id: press_notice.id, only_path: true)
    end

    def press_notice_task_url
      route_for(:task, planning_application, slug: task.full_slug.sub("confirm-press-notice", "press-notice"), new: true, only_path: true)
    end

    private

    def form_params(params)
      params.fetch(param_key, {}).permit(
        :published_at,
        :comment,
        documents: []
      )
    end

    def confirm_publication
      transaction do
        attrs = {published_at: published_at, comment: comment}
        attrs[:documents] = documents if documents.present?
        press_notice.update!(attrs)
        task.in_progress!
      end
    end

    def all_required_press_notices_published
      if press_notices.required.where(published_at: nil).any?
        errors.add(:base, "All required press notices must be confirmed as published before completing this task")
      end
    end
  end
end
