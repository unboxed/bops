# frozen_string_literal: true

module Tasks
  class ConfirmSiteNoticeForm < Form
    self.task_actions = %w[save_and_complete]

    attribute :displayed_at, :date
    attribute :documents, array: true

    after_initialize do
      @site_notice = planning_application.site_notices
    end

    attr_reader :site_notice

    private

    def form_params(params)
      params.fetch(param_key, {}).permit(:displayed_at, documents: [])
    end

    def save_and_complete
      super do
        @site_notice.update!(
          displayed_at: displayed_at,
          documents: documents
        )
      end
    end
  end
end
