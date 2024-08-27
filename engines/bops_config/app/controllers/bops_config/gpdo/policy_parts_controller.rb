# frozen_string_literal: true

module BopsConfig
  module Gpdo
    class PolicyPartsController < BaseController
      before_action :set_policy_schedule
      before_action :build_policy_part, only: %i[new create]
      before_action :set_policy_parts, only: %i[index]
      before_action :set_policy_part, only: %i[edit update destroy]

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
        @part.attributes = policy_part_params

        respond_to do |format|
          if @part.save
            format.html { redirect_to gpdo_policy_schedule_policy_parts_path, notice: t(".success") }
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
            if @part.update(policy_part_params)
              redirect_to gpdo_policy_schedule_policy_parts_path, notice: t(".success")
            else
              render :edit
            end
          end
        end
      end

      def destroy
        respond_to do |format|
          format.html do
            if @part.destroy
              redirect_to gpdo_policy_schedule_policy_parts_path, notice: t(".success")
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
        params[:number]
      end

      def policy_part_params
        params.require(:policy_part).permit(*policy_part_attributes)
      end

      def policy_part_attributes
        %i[number name]
      end

      def build_policy_part
        @part = @schedule.policy_parts.new
      end

      def set_policy_part
        @part = set_policy_parts.find_by_number(policy_part_number)
      end
    end
  end
end
