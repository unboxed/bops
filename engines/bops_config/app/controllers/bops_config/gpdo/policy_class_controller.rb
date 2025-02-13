# frozen_string_literal: true

module BopsConfig
  module Gpdo
    class PolicyClassController < BaseController
      before_action :set_policy_schedule
      before_action :set_policy_part
      before_action :build_policy_class, only: %i[new create]
      before_action :set_policy_classes, only: %i[index]
      before_action :set_policy_class, only: %i[edit update destroy]

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
        @policy_class.attributes = policy_class_params

        respond_to do |format|
          if @policy_class.save
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
            if @policy_class.update(policy_class_params.except(:section))
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
            if @policy_class.destroy
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
        params[:section]
      end

      def policy_class_params
        params.require(:policy_class).permit(*policy_class_attributes)
      end

      def policy_class_attributes
        %i[section name url]
      end

      def build_policy_class
        @policy_class = @part.policy_classes.new
      end

      def set_policy_class
        @policy_class = set_policy_classes.find_by_section(policy_class_section)
      end

      def set_policy_part
        @part = set_policy_parts.find_by_number(policy_part_number)
      end

      def redirect_path
        gpdo_policy_schedule_policy_part_policy_class_index_path(@schedule.number, @part.number)
      end
    end
  end
end
