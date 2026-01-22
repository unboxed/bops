# frozen_string_literal: true

module AccordionSections
  class ApplicationInformationComponent < AccordionSections::BaseComponent
    def initialize(planning_application:, show_edit_link: true)
      @planning_application = planning_application
      @show_edit_link = show_edit_link
    end

    private

    attr_reader :planning_application, :show_edit_link

    delegate(
      :uprn,
      :type_description,
      :session_id,
      :service_type,
      :parish_name,
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

    def alternative_reference
      planning_application.alternative_reference || t(".not_provided")
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

    def full_address
      address = planning_application.full_address
      return address unless (source = planning_application.address_source)

      safe_join([
        helpers.content_tag(:p, address),
        "Address source: ",
        helpers.content_tag(:strong, source)
      ])
    end

    def ward
      if planning_application.postcode.present?
        safe_join([
          helpers.tag.p(planning_application.ward),
          helpers.govuk_link_to(t(".view_on_mapit"), mapit_link, new_tab: true)
        ])
      else
        t(".a_postcode_is")
      end
    end

    def requested_services
      if planning_application.additional_services.any?
        safe_join(planning_application.additional_services.map { it.to_s.humanize }, ",")
      else
        "None"
      end
    end

    def location
      govuk_link_to(t(".view_site_on"), map_link, new_tab: true)
    end
  end
end
