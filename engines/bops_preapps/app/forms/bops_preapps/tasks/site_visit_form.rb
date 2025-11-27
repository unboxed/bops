# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class SiteVisitForm < BaseForm
      include DateValidateable #this had to be included in order to allow the date validation methods.

      attribute :visited_at, :date
      attribute :address, :string

      attr_reader :site_visits, :site_visit
      attr_accessor :visited_at, :address, :comment, :documents, :neighbour_id, :decision
      validates :visited_at, presence: true, date: {on_or_before: :current}
      validates :address, presence: true 
      # the comment also needs validating/

      def initialize(task)
        super
        @site_visits = @planning_application.site_visits.by_created_at_desc.includes(:created_by)
      end
      
      def update(params)
        return false unless valid?
        site_visit = @planning_application.site_visits.new
        # site_visit does not save correctly when invalid fields are supplied, but the rescue block only determines a high level error rather than individual field errors on the form.
        ActiveRecord::Base.transaction do
          site_visit.update!(params)
          task.update!(status: :completed) #
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
