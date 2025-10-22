# frozen_string_literal: true

module PlanningApplications
  module Information
    class BaseController < AuthenticationController
      before_action :set_planning_application
      before_action :set_information_navigation

      helper_method :documents_label,
        :constraints_label,
        :site_history_label,
        :consultees_label,
        :neighbours_label,
        :nav_items

      private

      def current_section
        :overview
      end

      def nav_items
        @information_nav_items || []
      end

      def set_information_navigation
        @information_nav_items = [
          navigation_item(
            "Overview",
            planning_application_information_path(@planning_application),
            current_section == :overview
          ),
          navigation_item(
            documents_label,
            planning_application_information_documents_path(@planning_application),
            current_section == :documents
          ),
          navigation_item(
            constraints_label,
            planning_application_information_constraints_path(@planning_application),
            current_section == :constraints
          )
        ]

        if consultation_navigation_applicable?
          @information_nav_items << navigation_item(
            consultees_label,
            planning_application_information_consultees_path(@planning_application),
            current_section == :consultees
          )

          if neighbour_navigation_applicable?
            @information_nav_items << navigation_item(
              neighbours_label,
              planning_application_information_neighbours_path(@planning_application),
              current_section == :neighbours
            )
          end
        end

        @information_nav_items << navigation_item(
          site_history_label,
          planning_application_information_site_history_path(@planning_application),
          current_section == :site_history
        )
      end

      def documents_label
        count = @planning_application.documents.active.count
        "Documents (#{count})"
      end

      def constraints_label
        if @planning_application.constraints_checked?
          count = @planning_application.planning_application_constraints.count
          "Constraints (#{count})"
        else
          "Constraints (0)"
        end
      end

      def site_history_label
        count = @planning_application.site_histories.count
        "Site history (#{count})"
      end

      def consultees_label
        count = @planning_application.consultation&.consultees&.count.to_i
        "Consultees (#{count})"
      end

      def neighbours_label
        count = @planning_application.consultation&.neighbours&.count.to_i
        "Neighbours (#{count})"
      end

      def neighbour_navigation_applicable?
        @planning_application.application_type.consultation? && @planning_application.neighbour_consultation_feature?
      end

      def consultation_navigation_applicable?
        @planning_application.application_type.consultation?
      end

      def navigation_item(text, href, current)
        {text:, href:, current:}
      end
    end
  end
end
