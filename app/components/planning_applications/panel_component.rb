# frozen_string_literal: true

module PlanningApplications
  class PanelComponent < ViewComponent::Base
    def initialize(planning_applications:, type:, search_filter: nil, current_user:, exclude_others: nil)
      @planning_applications = planning_applications
      @type = type
      @search_filter = search_filter
      @exclude_others = exclude_others
      @current_user = current_user
    end

    attr_reader :planning_applications, :type, :search_filter, :exclude_others, :current_user

    def title
      type == :all ? all_title : t(".#{type}")
    end

    def all_title
      exclude_others ? t(".all_your_applications") : t(".all_applications")
    end

    def attributes
      if exclude_others
        your_application_attributes
      else
        try("#{type}_attributes") || default_attributes
      end
    end

    def all_attributes
      %i[formatted_expiry_date reference status_tag full_address description user_name]
    end

    def your_application_attributes
      %i[reference full_address application_type_with_status formatted_expiry_date remaining_days_status_tag status_tag]
    end

    def closed_attributes
      %i[reference outcome formatted_outcome_date full_address description]
    end

    def awaiting_determination_attributes
      default_attributes.tap do |array|
        array[5] = :formatted_awaiting_determination_at
      end
    end

    def default_attributes
      %i[
        reference
        full_address
        application_type_with_status
        formatted_expiry_date
        remaining_days_status_tag
        status_tag
        user_name
      ]
    end
  end
end
