# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class SiteVisitForm < BaseForm
      attr_reader :site_visits

      def initialize(task)
        super

        @site_visits = @planning_application.site_visits.by_created_at_desc.includes(:created_by)
        @is_submitting_task = false
      end

      def update(params)
        if @is_submitting_task
          begin
            site_visit = @planning_application.site_visits.new

            ActiveRecord::Base.transaction do
              site_visit.update!(params)
              task.update!(status: :in_progress)
            end
          rescue ActiveRecord::RecordInvalid
            false
          end
        elsif params[:button] == "save_draft" && !@task.completed?
          task.update(status: :in_progress)
        else
          task.update(status: :completed)
        end
      end

      def permitted_fields(params)
        if (@is_submitting_task = params[:task].present?)
          params.require(:task)
            .permit(:decision, :comment, :visited_at, :neighbour_id, :address, documents: [])
            .merge(created_by: Current.user)
        else
          params
        end
      end
    end
  end
end
