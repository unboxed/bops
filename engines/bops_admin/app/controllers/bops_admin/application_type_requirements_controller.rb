# frozen_string_literal: true

module BopsAdmin
  class ApplicationTypeRequirementsController < ApplicationController
    before_action :set_application_type_requirements, only: %i[edit update]
    before_action :set_application_type, only: %i[edit update]

    def edit
      respond_to do |format|
        format.html
        @categories = LocalAuthority::Requirement.categories
        @requirements = current_local_authority.requirements
      end
    end

    def update
      selected_requirement_ids = params[:application_type][:requirement_ids].reject { |id| id.blank? || id.to_i == 0 }.map(&:to_i)
      existing_requirement_ids = @application_type.application_type_requirements.pluck(:local_authority_requirement_id)

      # add new ones
      (selected_requirement_ids - existing_requirement_ids).each do |id|
        ApplicationTypeRequirement.create!(
          application_type_id: @application_type.id,
          local_authority_requirement_id: id
        )
      end

      # destroy removed ones
      (existing_requirement_ids - selected_requirement_ids).each do |id|
        ApplicationTypeRequirement.where(
          application_type_id: @application_type.id,
          local_authority_requirement_id: id
        ).destroy_all
      end

      redirect_to application_type_path(@application_type), notice: t(".success")
    end

    private

    def application_type_id
      Integer(params[:application_type_id])
    end

    def set_application_type
      @application_type = current_local_authority.application_types.find(application_type_id)
    end

    def set_local_authority_requirements
      @requirements = current_local_authority.requirements
    end

    def set_application_type_requirements
      @application_type_requirements = ApplicationTypeRequirement.includes(:local_authority_requirement).where(
        local_authority_requirement: {local_authority_id: current_local_authority.id},
        application_type_id: application_type_id
      )
    end

    def set_application_type_requirement
      @application_type_requirement = ApplicationTypeRequirement.find_by(
        local_authority_requirement: {local_authority_id: current_local_authority.id},
        application_type_id: application_type_id
      )
    end
  end
end
