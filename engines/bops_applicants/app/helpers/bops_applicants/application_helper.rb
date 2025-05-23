# frozen_string_literal: true

module BopsApplicants
  module ApplicationHelper
    include BopsCore::ApplicationHelper

    def applicants_host
      "#{current_local_authority.subdomain}.#{Rails.application.config.applicants_domain}"
    end

    def bops_host
      "#{current_local_authority.subdomain}.#{Rails.application.config.domain}"
    end

    def formatted_address(planning_application)
      address = [
        planning_application.address_1,
        planning_application.address_2,
        planning_application.town,
        planning_application.postcode
      ].compact_blank.join("\n")

      simple_format(address, {}, wrapper_tag: "span")
    end

    def header_link
      content_for(:header_link) || root_path
    end

    def page_title
      t(:page_title, scope: "bops_applicants", council: current_local_authority.short_name)
    end

    def public_planning_guides_url
      main_app.public_planning_guides_url(host: bops_host)
    end

    def staging_environment?
      BopsApplicants.env.staging?
    end

    def stimulus_tag(controller, values: {}, &)
      tag.div(data: {controller:}.merge(stimulus_values(controller, values)), &)
    end

    def tag_colour(status)
      case status
      when "supportive"
        "green"
      when "objection"
        "red"
      else
        "yellow"
      end
    end

    def url_for_document(document)
      main_app.uploaded_file_url(document.blob, access_control_params)
    end

    def url_for_representation(document, transformations)
      main_app.uploaded_file_url(document.representation(transformations), access_control_params)
    end

    private

    def stimulus_values(controller, hash)
      hash.transform_keys { |key| :"#{controller}_#{key}_value" }
    end
  end
end
