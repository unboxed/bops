# frozen_string_literal: true

module BopsApplicants
  module ApplicationHelper
    include BopsCore::ApplicationHelper

    def formatted_address(planning_application)
      address = [
        planning_application.address_1,
        planning_application.address_2,
        planning_application.town,
        planning_application.postcode
      ].compact_blank.join("\n")

      simple_format(address, {}, wrapper_tag: "span")
    end

    def page_title
      t(:page_title, scope: "bops_applicants", council: current_local_authority.short_name)
    end

    def staging_environment?
      BopsApplicants.env.staging?
    end

    def stimulus_tag(controller, values: {}, &)
      tag.div(data: {controller:}.merge(stimulus_values(controller, values)), &)
    end

    private

    def stimulus_values(controller, hash)
      hash.transform_keys { |key| :"#{controller}_#{key}_value" }
    end
  end
end
