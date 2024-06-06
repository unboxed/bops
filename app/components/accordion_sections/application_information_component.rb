# frozen_string_literal: true

module AccordionSections
  class ApplicationInformationComponent < AccordionSections::BaseComponent
    private

    delegate(
      :uprn,
      :type_description,
      :full_address,
      to: :planning_application
    )

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
