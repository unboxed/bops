# frozen_string_literal: true

module Tasks
  class CheckDescriptionForm < BaseForm
    attr_reader :enforcement

    def initialize(task)
      super

      @enforcement = case_record.caseable
    end

    def permitted_fields(params)
      params.require(:enforcement).permit(:description)
    end

    def update(params)
      enforcement.update!(params)
      task.update!(status: "completed")
    end

    def redirect_url
      edit_task_path(case_record, parent)
    end
  end
end
