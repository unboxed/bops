# frozen_string_literal: true

module PlanningApplications
  class PanelComponent < ViewComponent::Base
    include Pagy::Backend

    def initialize(planning_applications:, type:, search: nil)
      @planning_applications = planning_applications
      @type = type
      @search = search
    end

    delegate :exclude_others?, to: :search, allow_nil: true
    delegate :all_applications_title, to: :search, allow_nil: true

    attr_reader :type, :search

    def before_render
      if type == :all
        @pagy, @paginated_applications = pagy(@planning_applications)
      end
    end

    def planning_applications
      case type
      when :all
        @paginated_applications
      else
        @planning_applications
      end
    end

    def pagination
      return unless @pagy.pages > 1

      render(PaginationComponent.new(pagy: @pagy))
    end

    def title
      (type == :all) ? all_applications_title : t(".#{type}")
    end

    def attributes
      if exclude_others?
        your_application_attributes
      else
        try("#{type}_attributes") || default_attributes
      end
    end

    def all_attributes
      %i[formatted_expiry_date reference status_tag full_address description user_name]
    end

    def your_application_attributes
      %i[reference full_address application_type_with_status formatted_expiry_date days_status_tag status_tag]
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
        days_status_tag
        status_tag
        user_name
      ]
    end
  end
end
