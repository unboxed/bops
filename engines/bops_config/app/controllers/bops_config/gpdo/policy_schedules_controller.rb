# frozen_string_literal: true

module BopsConfig
  module Gpdo
    class PolicySchedulesController < BaseController
      before_action :build_policy_schedule, only: %i[new create]
      before_action :set_policy_schedules, only: %i[index]
      before_action :set_policy_schedule, only: %i[edit update destroy]

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
        @schedule.attributes = policy_schedule_params

        respond_to do |format|
          if @schedule.save
            format.html { redirect_to gpdo_policy_schedules_path, notice: t(".success") }
          else
            format.html { render :new }
          end
        end
      end

      def show
        respond_to do |format|
          format.html
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
            if @schedule.update(policy_schedule_params.except(:number))
              redirect_to gpdo_policy_schedules_path, notice: t(".success")
            else
              render :edit
            end
          end
        end
      end

      def destroy
        respond_to do |format|
          format.html do
            if @schedule.destroy
              redirect_to gpdo_policy_schedules_path, notice: t(".success")
            else
              render :edit
            end
          end
        end
      end

      private

      def policy_schedule_params
        params.require(:policy_schedule).permit(*policy_schedule_attributes)
      end

      def policy_schedule_attributes
        %i[number name]
      end

      def build_policy_schedule
        @schedule = PolicySchedule.new
      end

      def policy_schedule_number_params
        params[:number]
      end
    end
  end
end
