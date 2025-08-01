# frozen_string_literal: true

module Tasks
  class << self
    def form_for(slug)
      FORM_HANDLERS.fetch(slug, BaseForm)
    end
  end

  FORM_HANDLERS = {
    "check-breach-report" => BaseForm,
    "investigate-and-decide" => BaseForm,
    "review-recommendation" => BaseForm,
    "serve-notice-and-monitor-compliance" => BaseForm,
    "process-an-appeal" => BaseForm,

    "check-report-details" => CheckReportDetailsForm
  }.freeze
end
