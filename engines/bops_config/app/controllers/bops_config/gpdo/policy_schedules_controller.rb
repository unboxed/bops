# frozen_string_literal: true

module BopsConfig
  module Gpdo
    class PolicySchedulesController < ApplicationController
      before_action :build_policy_schedule, only: %i[new create]
      before_action :set_policy_schedules, only: %i[index]
      before_action :set_policy_schedule, only: %i[show edit update destroy]

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

      def set_policy_schedule
        @schedule = PolicySchedule.find_by_number(policy_schedule_number)
      end

      def set_policy_schedules
        @schedules = PolicySchedule.all
      end

      def policy_schedule_number
        Integer(params[:number])
      rescue
        raise ActionController::BadRequest, "Invalid policy schedule number: #{params[:number].inspect}"
      end
    end
  end
end
