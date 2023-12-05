# frozen_string_literal: true

module AccordionSections
  class ApplicationInformationComponent < AccordionSections::BaseComponent
    private

    delegate(
      :closed_or_cancelled?,
      :uprn,
      :type_and_work_status,
      :full_address,
      to: :planning_application
    )

    def description_change_link_text
      if description_change_request.present?
        t(".view_requested_change")
      elsif !closed_or_cancelled?
        t(".propose_a_change")
      end
    end

    def description_change_link_path
      if description_change_request.present?
        planning_application_validation_description_change_validation_request_path(
          planning_application,
          description_change_request
        )
      elsif !closed_or_cancelled?
        new_planning_application_validation_description_change_validation_request_path(
          planning_application,
          type: "description_change"
        )
      end
    end

    def ward_type
      if planning_application.postcode.present?
        planning_application.ward_type
      else
        t(".a_postcode_is")
      end
    end

    def case_officer
      planning_application.user&.name || t(".not_assigned")
    end

    def payment_amount
      number_to_currency(planning_application.payment_amount || 0, unit: "£")
    end

    def description_change_request
      @description_change_request ||= planning_application
        .description_change_validation_requests.open
        .last
    end

    def payment_reference
      planning_application.payment_reference || t(".exempt")
    end

    def work_already_started
      (planning_application.work_status == "proposed") ? t(".no") : t(".yes")
    end

    def map_link
      "https://google.co.uk/maps/place/#{CGI.escape(full_address)}"
    end

    def mapit_link
      "https://mapit.mysociety.org/postcode/#{postcode}.html"
    end

    def postcode
      planning_application.postcode.gsub(/\s+/, "").upcase
    end
  end
end
