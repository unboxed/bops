# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class DrawRedLineBoundaryForm < BaseForm
      include ActiveModel::Attributes

      attribute :boundary_geojson, :string

      delegate :errors, to: :planning_application, prefix: true

      def update(params)
        assign_attributes(boundary_attributes(params))
        save
      end

      def save
        persist_boundary && task.complete!
      end

      def permitted_fields(params)
        params
      end

      def sitemap_documents
        @sitemap_documents ||= planning_application.documents.with_siteplan_tags
      end

      private

      def boundary_attributes(params)
        return {} unless params[:planning_application]

        params.require(:planning_application).permit(:boundary_geojson)
      end

      def persist_boundary
        return true if boundary_geojson.blank?

        audit_action = planning_application.boundary_geojson.blank? ? "created" : "updated"

        planning_application.update(boundary_geojson:, boundary_created_by: Current.user).tap do |success|
          planning_application.audit_boundary_geojson!(audit_action) if success
        end
      end
    end
  end
end
