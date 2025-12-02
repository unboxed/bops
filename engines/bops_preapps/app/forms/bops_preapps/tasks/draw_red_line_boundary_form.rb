# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class DrawRedLineBoundaryForm < BaseForm
      include ActiveModel::Attributes

      attribute :boundary_geojson, :string

      validates :boundary_geojson, presence: true

      def boundary_geojson=(value)
        return if value.blank? || value == "null"
        super
      end

      def update(params)
        assign_attributes(boundary_geojson: params.dig(:planning_application, :boundary_geojson))
        save
      end

      def save
        return false unless valid?

        ApplicationRecord.transaction do
          persist_boundary!
          task.complete!
        end
        true
      rescue ActiveRecord::RecordInvalid
        false
      end

      def sitemap_documents
        @sitemap_documents ||= planning_application.documents.with_siteplan_tags
      end

      def permitted_fields(params)
        params
      end

      private

      def persist_boundary!
        return if boundary_geojson.blank?

        audit_action = planning_application.boundary_geojson.blank? ? "created" : "updated"

        planning_application.update!(boundary_geojson:, boundary_created_by: Current.user)
        planning_application.audit_boundary_geojson!(audit_action)
      end
    end
  end
end
