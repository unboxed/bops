# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class CloseCaseForm < BaseForm
      attr_reader :enforcement

      def initialize(task)
        super

        @enforcement = case_record.caseable
      end

      def permitted_fields(params)
        params.require(:enforcement).permit(:reason, :other_reason, :detail)
      end

      def update(params)
        ActiveRecord::Base.transaction do
          closed_reason = (params[:reason] == "other") ? params[:other_reason] : I18n.t(params[:reason])
          enforcement.update!(closed_reason:, closed_detail: params[:detail])
          enforcement.close!
          task.update!(status: "completed")
        end
      end
    end
  end
end
