# frozen_string_literal: true

module PlanningApplications
  class PanelComponent < ViewComponent::Base
    def initialize(planning_applications:, type:, filter: nil, search: nil, exclude_others: nil, current_user:)
      @planning_applications = planning_applications
      @type = type
      @search = search
      @filter = filter
      @exclude_others = exclude_others
      @current_user = current_user
    end

    attr_reader :planning_applications, :type, :search, :exclude_others, :filter, :current_user

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
      %i[formatted_expiry_date reference status_tag full_address description]
    end

    def your_application_attributes
      %i[reference full_address application_type_name formatted_expiry_date remaining_days_status_tag status_tag]
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
        application_type_name
        formatted_expiry_date
        remaining_days_status_tag
        status_tag
        user_name
      ]
    end
  end
end
