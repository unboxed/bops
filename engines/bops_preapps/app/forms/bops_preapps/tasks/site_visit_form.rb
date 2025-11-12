# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class SiteVisitForm < BaseForm
      attr_reader :site_visits

      def initialize(task)
        super

        @site_visits = @planning_application.site_visits.by_created_at_desc.includes(:created_by)
      end

      def update(params)
        site_visit = @planning_application.site_visits.new

        ActiveRecord::Base.transaction do
          site_visit.update!(params)
          task.update!(status: :completed)
        end
      rescue ActiveRecord::RecordInvalid
        false
      end

      def permitted_fields(params)
        params.require(:task)
          .permit(:decision, :comment, :visited_at, :neighbour_id, :address, documents: [])
          .merge(created_by: Current.user)
      end
    end
  end
end
