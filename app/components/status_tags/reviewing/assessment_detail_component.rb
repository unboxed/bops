# frozen_string_literal: true

module StatusTags
  module Reviewing
    class AssessmentDetailComponent < StatusTags::BaseComponent
      include AssessmentDetailable

      def initialize(assessment_detail:, planning_application:)
        @planning_application = planning_application
        @assessment_detail = assessment_detail
        super(status:)
      end

      private

      attr_reader :planning_application, :assessment_detail

      def status
        if assessment_detail.update_required?
          :awaiting_changes
        elsif updated?
          :updated
        elsif assessment_detail.review_status.nil?
          :not_started
        elsif assessment_detail.review_complete?
          :complete
        end
      end

      def updated?
        assessment_detail_updated?(assessment_detail)
      end
    end
  end
end
