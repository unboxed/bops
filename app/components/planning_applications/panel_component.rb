# frozen_string_literal: true

module PlanningApplications
  class PanelComponent < ViewComponent::Base
    include Pagy::Backend

    def initialize(planning_applications:, type:, search: nil)
      @planning_applications = planning_applications
      @type = type
      @search = search
    end

    attr_reader :type, :search

    def before_render
      @pagy, @paginated_applications = pagy(@planning_applications)
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

      govuk_pagination(pagy: @pagy)
    end

    def title
      t(".#{type}")
    end

    def attributes
      try("#{type}_attributes") || default_attributes
    end

    def all_attributes
      %i[reference full_address description days_status_tag status_tag formatted_expiry_date user_name]
    end

    def mine_attributes
      %i[reference full_address formatted_expiry_date days_status_tag status_tag]
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
        formatted_expiry_date
        days_status_tag
        status_tag
        user_name
      ]
    end
  end
end
