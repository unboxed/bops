# frozen_string_literal: true

module Tasks
  class CheckReportDetailsForm < BaseForm
    def initialize(task, enforcement:)
      super(task)
      @enforcement = enforcement
    end

    def permitted_fields(params)
      params.require(:enforcement).permit(:urgent)
    end

    def update(params)
      @enforcement.update!(params)
      @task.update!(status: "completed")
    end

    def redirect_url
      task_path(case_type: "enforcement", case_id: @case_record, slug: parent.full_slug)
    end
  end
end
