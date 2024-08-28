# frozen_string_literal: true

module BopsConfig
  module Gpdo
    class PolicySectionsController < BaseController
      before_action :set_policy_schedule
      before_action :set_policy_part
      before_action :set_policy_class
      before_action :build_policy_section, only: %i[new create]
      before_action :set_policy_sections, only: %i[index]
      before_action :set_policy_section, only: %i[edit update destroy]

      def index
        respond_to do |format|
          format.html
        end
      end

      def new
        respond_to do |format|
          format.html
        end
      end

      def create
        @policy_section.attributes = policy_section_params

        respond_to do |format|
          if @policy_section.save
            format.html { redirect_to redirect_path, notice: t(".success") }
          else
            format.html { render :new }
          end
        end
      end

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          format.html do
            if @policy_section.update(policy_section_params)
              redirect_to redirect_path, notice: t(".success")
            else
              render :edit
            end
          end
        end
      end

      def destroy
        respond_to do |format|
          format.html do
            if @policy_section.destroy
              redirect_to redirect_path, notice: t(".success")
            else
              render :edit
            end
          end
        end
      end

      private

      def policy_schedule_number_params
        params[:policy_schedule_number]
      end

      def policy_part_number_params
        params[:policy_part_number]
      end

      def policy_class_section_params
        params[:policy_class_section]
      end

      def set_policy_part
        @part = set_policy_parts.find_by_number(policy_part_number)
      end

      def set_policy_class
        @policy_class = set_policy_classes.find_by_section(policy_class_section)
      end

      def policy_section
        params[:section]
      rescue
        raise ActionController::BadRequest, "Invalid policy section: #{params[:section].inspect}"
      end

      def policy_section_params
        params.require(:policy_section).permit(*policy_section_attributes)
      end

      def policy_section_attributes
        %i[section title description]
      end

      def build_policy_section
        @policy_section = @policy_class.policy_sections.new
      end

      def set_policy_section
        @policy_section = set_policy_sections.find_by_section(policy_section)
      end

      def set_policy_sections
        @policy_sections = @policy_class.policy_sections
      end

      def redirect_path
        gpdo_policy_schedule_policy_part_policy_class_policy_sections_path(@schedule.number, @part.number, @policy_class.section)
      end
    end
  end
end
