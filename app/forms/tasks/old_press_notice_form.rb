# frozen_string_literal: true

module Tasks
  class OldPressNoticeForm < Form
    self.task_actions = %w[save_and_complete]

    attribute :required, :boolean
    attribute :reasons, :list, default: []
    attribute :other_reason, :string, default: nil

    after_initialize do
      @press_notices = planning_application.press_notices
      if params[:new]
        @press_notice = @press_notices.new
      else
        @press_notice = @press_notices.first || @press_notices.new
        if press_notice.persisted?
          self.required = press_notice.required if required.nil?
          self.reasons = press_notice.reasons if reasons.empty?
          self.other_reason ||= press_notice.other_reason
        end
      end
    end

    with_options on: :save_and_complete do
      validates :required, inclusion: {in: [true, false], message: "Select whether a press notice is required"}
      validates :reasons, presence: {message: "Select a reason for the press notice"}, if: :press_notice_required?
      validates :other_reason, presence: {message: "Provide other reason for press notice"}, if: :other_reason_selected?
    end

    attr_reader :press_notice, :press_notices

    def new_press_notice_url
      route_for(:task, planning_application, slug: task.full_slug, new: true, only_path: true)
    end

    private

    def press_notice_required?
      required == true
    end

    def other_reason_selected?
      reasons.include?("other")
    end

    def form_params(params)
      params.fetch(param_key, {}).permit(
        :required,
        :other_reason,
        reasons: []
      )
    end

    def save_and_complete
      super do
        press_notice.update!(
          required: required,
          reasons: reasons.flatten,
          other_reason: other_reason
        )
        if required
          SendPressNoticeEmailJob.perform_later(@press_notice, Current.user)
        end
      end
    end
  end
end
