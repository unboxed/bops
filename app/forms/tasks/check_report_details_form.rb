# frozen_string_literal: true

module Tasks
  class CheckReportDetailsForm < BaseForm
    attr_reader :enforcement

    def initialize(task)
      super

      @enforcement = case_record.caseable
    end

    def permitted_fields(params)
      params.require(:enforcement).permit(:urgent)
    end

    def update(params)
      ActiveRecord::Base.transaction do
        enforcement.update!(params)
        task.update!(status: "completed")
      end
    rescue ActiveRecord::RecordInvalid
      flash.now[:alert] = "Unable to update, please contact support"
      render template_for(:edit)
    end

    def redirect_url
      task_path(case_record, parent)
    end

    def success_message
      "Check report details successfully completed"
    end
  end
end
